// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {
    function mintItem(address _to) external returns (uint256 itemId);

    function burnItem(uint256 _tokenId) external;

    function tokensOf(
        address _owner
    ) external view returns (uint256[] memory ownerTokens);
}

contract MintableItem is
    INFT,
    ReentrancyGuardUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable
{
    ///////////////////////////////
    // CONFIGURABLES & VARIABLES //
    ///////////////////////////////

    string public baseURI;

    uint256 public royaltyFeePercentage;

    ////////////////////////////
    // CONSTANTS & IMMUTABLES //
    ////////////////////////////

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address public constant TOKEN_SPLITTER = 0x58AB8Fe4e78Da632FFca31D120AD766ae981A4D7; // Island Treasury

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    /////////////////////
    // CONTRACT EVENTS //
    /////////////////////

    event ItemMinted(address indexed to, uint256 indexed tokenId);

    //////////////////////////////
    // INITIALIZER AND FALLBACK //
    //////////////////////////////

    function initialize() public initializer {
        __ERC721_init("Function Island NFTs", "fiNFT");
        __ReentrancyGuard_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITELISTED_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        royaltyFeePercentage = 3000;
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // NFTs held by an address
    function tokensOf(
        address _owner
    ) external view override returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalItems = totalSupply();
            uint256 resultIndex = 0;

            uint256 itemId;

            for (itemId = 1; itemId <= totalItems; itemId++) {
                if (ownerOf(itemId) == _owner) {
                    result[resultIndex] = itemId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    // ERC2981 Support (Royalty Info)
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        try this.ownerOf(_tokenId) {
            receiver = TOKEN_SPLITTER;
            royaltyAmount = (_salePrice * royaltyFeePercentage) / 10000;
        } catch {
            revert("ERC2981Royalties: Royalty info for nonexistent token");
        }
    }

    // Base URI for token metadata
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Override the token URI function to return the token ID
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Override the supportsInterface function
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721URIStorageUpgradeable,
            ERC721EnumerableUpgradeable,
            AccessControlUpgradeable,
            IERC165
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // This function only handles minting of items assignment.
    // Collect payment via the Minter contract on the front.
    function mintItem(
        address _to
    ) external override onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        // Get new token ID
        tokenId = totalSupply() + 1;

        // Mint the item to caller and set the token ID
        _safeMint(_to, tokenId);

        // Build the token URI and set it
        string memory constructedTokenURI = string(toString(tokenId));

        // Set the token URI
        _setTokenURI(tokenId, constructedTokenURI);

        // Emit the minted event
        emit ItemMinted(_to, tokenId);
    }

    // Burn an item
    function burnItem(
        uint256 _tokenId
    ) external override onlyRole(BURNER_ROLE) {
        _burn(_tokenId);
    }

    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////

    function setBaseURI(string memory _uri) external onlyRole(MANAGER_ROLE) {
        baseURI = _uri;
    }

    function setTokenURI(
        uint256 _tokenId,
        string memory _uri
    ) external onlyRole(MANAGER_ROLE) {
        _setTokenURI(_tokenId, _uri);
    }

    function setMinter(
        address _minter,
        bool _enabled
    ) external onlyRole(MANAGER_ROLE) {
        if (_enabled) {
            grantRole(MINTER_ROLE, _minter);
        } else {
            revokeRole(MINTER_ROLE, _minter);
        }
    }

    function setBurner(
        address _burner,
        bool _enabled
    ) external onlyRole(MANAGER_ROLE) {
        if (_enabled) {
            grantRole(BURNER_ROLE, _burner);
        } else {
            revokeRole(BURNER_ROLE, _burner);
        }
    }

    function setManager(
        address _manager,
        bool _enabled
    ) external onlyRole(MANAGER_ROLE) {
        if (_enabled) {
            grantRole(MANAGER_ROLE, _manager);
        } else {
            revokeRole(MANAGER_ROLE, _manager);
        }
    }

    function setRoyaltyFeePercentage(
        uint256 _percentage
    ) external onlyRole(MANAGER_ROLE) {
        royaltyFeePercentage = _percentage;
    }

    ////////////////////////
    // INTERNAL FUNCTIONS //
    ////////////////////////

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        super._increaseBalance(account, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OpenZeppelin's implementation
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
