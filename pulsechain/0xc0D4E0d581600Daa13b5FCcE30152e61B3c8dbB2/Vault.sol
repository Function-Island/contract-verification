// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IStrategy {
    function vault() external view returns (address);

    function want() external view returns (IERC20);

    function beforeDeposit() external;

    function deposit() external;

    function withdraw(uint256) external;

    function balanceOf() external view returns (uint256);

    function balanceOfWant() external view returns (uint256);

    function balanceOfPool() external view returns (uint256);

    function harvest() external;

    function retireStrat() external;

    function panic() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    function unirouter() external view returns (address);

    function lpToken() external view returns (address);
}

contract Vault is ERC20, AccessControl {
    ////////////////
    // INTERFACES //
    ////////////////

    IERC20 public token;

    ///////////////////////////////
    // CONFIGURABLES & VARIABLES //
    ///////////////////////////////

    address public strategy;

    ////////////////////////////
    // CONSTANTS & IMMUTABLES //
    ////////////////////////////

    bytes32 public OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /////////////////////
    // CONTRACT EVENTS //
    /////////////////////

    event UpgradeStrat(address implementation);

    ////////////////////////////
    // CONSTRUCTOR & FALLBACK //
    ////////////////////////////

    constructor() ERC20("Function Island Vault", "fiVAULT") {
        token = IERC20(address(0));
        strategy = address(0);

        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function balance() public view returns (uint) {
        uint256 tokenBal = token.balanceOf(address(this));
        uint256 stratBal = IStrategy(strategy).balanceOfWant();
        return (tokenBal + stratBal);
    }

    function available() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPricePerFullShare() public view returns (uint256) {
        uint256 ts = totalSupply();
        return ts == 0 ? 1e18 : ((balance() * 1e18) / ts);
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // MAX APE
    function maxDeposit() external {
        deposit(token.balanceOf(msg.sender));
    }

    // MAX JEET
    function maxWithdraw() external {
        withdraw(balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 _after = token.balanceOf(address(this));
        _amount = (_after - _before); // Additional check for deflationary tokens

        uint256 shares = 0;
        uint256 ts = totalSupply();

        if (ts == 0) {
            shares = _amount;
        } else {
            shares = (((_amount * ts)) / _pool);
        }

        _mint(msg.sender, shares);

        earn();
    }

    function withdraw(uint256 _shares) public {
        uint256 ts = totalSupply();
        uint256 r = (((balance() * _shares)) / ts);
        _burn(msg.sender, _shares);

        uint b = token.balanceOf(address(this));
        if (b < r) {
            uint _withdraw = (r - b);
            IStrategy(strategy).withdraw(_withdraw);
            uint _after = token.balanceOf(address(this));
            uint _diff = (_after - b);
            if (_diff < _withdraw) {
                r = (b + _diff);
            }
        }

        token.transfer(msg.sender, r);
    }

    function earn() public {
        uint _bal = available();
        token.transfer(strategy, _bal);
        IStrategy(strategy).deposit();
    }

    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////

    function upgradeStrat(address _strategy) public onlyRole(OPERATOR_ROLE) {
        require(
            _strategy != address(0) &&
                _strategy != address(this) &&
                _strategy != msg.sender,
            "INVALID_STRATEGY_CANDIDATE"
        );

        if (address(token) != address(0)) {
            require(
                IStrategy(_strategy).lpToken() == address(token),
                "New strategy must have same token"
            );
        }

        if (address(strategy) != address(0)) {
            IStrategy(strategy).retireStrat();
        }

        strategy = _strategy;
        token = IERC20(IStrategy(strategy).lpToken());

        earn();

        emit UpgradeStrat(_strategy);
    }

    function inCaseTokensGetStuck(
        address _token
    ) external onlyRole(OPERATOR_ROLE) {
        require(_token != address(token), "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
}
