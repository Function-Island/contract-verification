// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAccessControl {
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AccessControlBadConfirmation();
    
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface ITreasury {
    function getBalance(address token) external view returns (uint256);

    function withdraw(address token, uint256 _amount) external;
    function withdrawTo(address token, address _to, uint256 _amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

contract MintFeeProcessor is AccessControl, ReentrancyGuard {

    modifier onlyAllowedEvery(uint256 timeframe) {
        // Check if the time since last sell is more than or equal to timeframe
        uint256 timeSinceLastSell = (block.timestamp - lastSellTime);
        require(timeSinceLastSell >= timeframe, "Too soon");
        _;
    }

    //////////////////////////
    // INTERFACES & IMPORTS //
    //////////////////////////

    IERC20 public constant WPLS = IERC20(0xA1077a294dDE1B09bB078844df40758a5D0f9a27);
    IERC20 public constant ISLAND = IERC20(0xDFB10795E6fE7D0Db68F9778Ba4C575a28E8Cd4c);

    IUniswapV2Router02 public swapRouter = IUniswapV2Router02(0x165C3410fC91EF562C50559f7d2289fEbed552d9);

    address public constant treasury = 0x58AB8Fe4e78Da632FFca31D120AD766ae981A4D7;

    ///////////////////////////////
    // CONFIGURABLES & VARIABLES //
    ///////////////////////////////

    address[] public tokens;

    uint256 public sellEpoch;
    uint256 public lastSellTime;
    uint256 public sellPercentage;

    ////////////////////////////
    // CONSTANTS & IMMUTABLES //
    ////////////////////////////

    uint256 public constant FST = 3 minutes;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    ////////////////////////////
    // CONSTRUCTOR & FALLBACK //
    ////////////////////////////

    constructor () {
        lastSellTime = block.timestamp;
        sellEpoch = 6 hours;

        _grantRole(MANAGER_ROLE, msg.sender);
    }

    receive () external payable {
        payable(treasury).transfer(msg.value);
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // Get the balance of a token
    function tokenBalance(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // Get a swap path for a token
    function swapPath(address from, address to) public pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        return path;
    }

    // Calculate a percentage
    function calculatePercentage(uint256 _amount, uint256 _percentage) public pure returns (uint256) {
        return (_amount * _percentage) / 10000;
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // Function #1: 
    // Sell ISLAND at a rate of 0.25% of balance per 6 hours (1% per day).abi
    // Returns WPLS to buy other tokens with (buyTokens).
    function swapISLAND() external nonReentrant onlyAllowedEvery(sellEpoch) {

        // Get the balance of ISLAND & Approve the Swap Router
        uint256 islandBal = tokenBalance(address(ISLAND));
        ISLAND.approve(address(swapRouter), islandBal);

        // Update the last sell time
        lastSellTime = block.timestamp;

        // Calculate the amount to sell
        uint256 amountIn = calculatePercentage(islandBal, sellPercentage);

        // Swap ISLAND for WPLS
        swapRouter.swapExactTokensForTokens(amountIn, 1, swapPath(address(ISLAND), address(WPLS)), address(this), block.timestamp + FST);
    }

    // Function #2:
    // Buy tokens with WPLS.
    // Returns tokens into the Island Treasury.
    function buyTokens() public payable nonReentrant {

        // Divide the WPLS between the eligible tokens
        uint256 perToken = tokenBalance(address(WPLS)) / tokens.length;

        // Approve the router to use WPLS
        approveRouterForToken(address(WPLS));
        
        // Buy tokens, itterating through the list of tokens
        for (uint256 i = 0; i < tokens.length; i++) {
            _buyTokens(tokens[i], perToken);
        }
    }

    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////

    // Set the tokens to buy with WPLS
    function setTokens(address[] memory _tokens) public onlyRole(MANAGER_ROLE) {
        tokens = _tokens;
    }

    // Set the manager of this contract
    function setManager(address _manager, bool _enabled) public onlyRole(MANAGER_ROLE) {
        if (_enabled) {
            grantRole(MANAGER_ROLE, _manager);
        } else {
            revokeRole(MANAGER_ROLE, _manager);
        }
    }

    // Set the sell epoch
    function setSellEpoch(uint256 _sellEpoch) public onlyRole(MANAGER_ROLE) {
        sellEpoch = _sellEpoch;
    }

    // Set the sell percentage
    function setSellPercentage(uint256 _sellPercentage) public onlyRole(MANAGER_ROLE) {
        sellPercentage = _sellPercentage;
    }

    // Set the swap router
    function setSwapRouter(address _swapRouter) public onlyRole(MANAGER_ROLE) {
        swapRouter = IUniswapV2Router02(_swapRouter);
    }

    // Approve the router to use a token
    function approveRouterForToken(address _token) public onlyRole(MANAGER_ROLE) {
        IERC20(_token).approve(address(swapRouter), type(uint256).max);
    }

    // Revoke the router to use a token
    function revokeRouterForToken(address _token) public onlyRole(MANAGER_ROLE) {
        IERC20(_token).approve(address(swapRouter), 0);
    }

    // Retrieve PLS from the contract
    function withdraw() public onlyRole(MANAGER_ROLE) {
        uint256 balance = address(this).balance;
        payable(treasury).transfer(balance);
    }

    // Retrieve tokens from the contract
    function withdrawToken(address _token) public onlyRole(MANAGER_ROLE) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(treasury, balance);
    }

    ////////////////////////
    // INTERNAL FUNCTIONS //
    ////////////////////////

    function _buyTokens(address token, uint256 _amount) internal {
        swapRouter.swapExactTokensForTokens(
            _amount,
            1,
            swapPath(address(WPLS), token),
            treasury,
            block.timestamp + FST
        );
    }
}
