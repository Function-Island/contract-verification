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

interface IWPLS is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IStaking {
    function reward(uint256 _amount) external;
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

contract RewardsProcessor is AccessControl {

    //////////////////////////
    // INTERFACES & IMPORTS //
    //////////////////////////

    IWPLS public constant WPLS = IWPLS(0xA1077a294dDE1B09bB078844df40758a5D0f9a27);

    IStaking public staking = IStaking(0xF67e922D7DfcE1DCea259741F854F6b08d795642);
    ITreasury public treasury = ITreasury(0x58AB8Fe4e78Da632FFca31D120AD766ae981A4D7);
    IUniswapV2Router02 public swapRouter = IUniswapV2Router02(0x165C3410fC91EF562C50559f7d2289fEbed552d9);

    ///////////////////////////////
    // CONFIGURABLES & VARIABLES //
    ///////////////////////////////

    address public rewardsToken;

    uint256 public emissionTimeframe;
    uint256 public bountyRewardPercentage;

    ////////////////////////////
    // CONSTANTS & IMMUTABLES //
    ////////////////////////////

    uint256 public constant FST = 3 minutes;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    //////////////////
    // DATA STORAGE //
    //////////////////

    mapping (address => uint256) public lastPayoutTime;
    mapping (address => uint256) public totalPaidOut;

    ////////////////////////////
    // CONSTRUCTOR & FALLBACK //
    ////////////////////////////

    constructor (address _rewardsToken) {

        bountyRewardPercentage = 500;

        emissionTimeframe = 24 hours;
        
        rewardsToken = _rewardsToken;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    receive () external payable {
        WPLS.deposit{value: msg.value}();
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // Calculate the time since the last payout
    function timeSinceLastPayout(address token) public view returns (uint256) {
        return block.timestamp - lastPayoutTime[token];
    }

    // Calculate the time until the next payout
    function timeToNextPayout(address token) public view returns (uint256) {
        uint256 timeSince = timeSinceLastPayout(token);
        if (timeSince >= emissionTimeframe) {
            return 0;
        } else {
            return emissionTimeframe - timeSince;
        }
    }

    // Calculate the percentage of a token balance required for a payout
    function calculatePayout(address token) public view returns (uint256) {
        uint256 bal = IERC20(token).balanceOf(address(treasury));
        if (bal > 0) {
            return (bal / 200);
        } else {
            return 0;
        }
    }

    // Calculate a percentage of an amount
    function calculatePercentage(uint256 amount, uint256 percentage) public pure returns (uint256) {
        return (amount * percentage) / 10000;
    }

    // Find a swap path from one token to another
    function swapPath(address from, address to) public pure returns (address[] memory path) {
        if (from == address(WPLS) || to == address(WPLS)) {
            path = new address[](2);
            path[0] = from;
            path[1] = to;
        } else {
            path = new address[](3);
            path[0] = from;
            path[1] = address(WPLS);
            path[2] = to;
        }
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // Extract set percentage of rewards from Treasury and swap to rewards token
    function prepare(address token) external {

        require(timeToNextPayout(token) == 0, "NOT_TIME_YET");

        // 1: Find how much to withdraw from Treasury
        uint256 emission = calculatePayout(token);
        
        // 2: Withdraw amount of token to this contract from Treasury
        treasury.withdrawTo(token, address(this), emission);

        // 3: If token is not WPLS...
        if (token != address(WPLS)) {

            // 3:1: Get how much of it there is now in this contract
            uint256 tokenBal = IERC20(token).balanceOf(address(this));
            
            // 3:2: Approve that much to be swapped for WPLS
            IERC20(token).approve(address(swapRouter), type(uint256).max);

            // 3:3: Swap that amount for WPLS
            swapRouter.swapExactTokensForTokens(tokenBal, 1, swapPath(address(token), address(WPLS)), address(this), block.timestamp + FST);
        }

        lastPayoutTime[token] = block.timestamp;
        totalPaidOut[token] += emission;
    }

    // Send rewards token to staking contract as rewards
    function distribute(address bountyHunter) external {

        // 1: Get rewards token balance
        uint256 wplsBal = IERC20(WPLS).balanceOf(address(this));

        // 2: Calculate Bounty
        uint256 bounty = calculatePercentage(wplsBal, bountyRewardPercentage);
        IERC20(WPLS).transfer(bountyHunter, bounty);

        // 3: Subtract bounty from rewards
        wplsBal = wplsBal - bounty;

        // 5: Approve staking to take these rewards
        IERC20(WPLS).approve(address(staking), wplsBal);

        // 6: Give rewards to stakers
        staking.reward(wplsBal);
    }

    //////////////////////////
    // RESTRICTED FUNCTIONS //
    //////////////////////////

    // Set the Treasury address & interface
    function setTreasury(address _treasury) external onlyRole(MANAGER_ROLE) {
        treasury = ITreasury(_treasury);
    }

    // Set the swap router address & interface
    function setRouter(address _router) external onlyRole(MANAGER_ROLE) {
        swapRouter = IUniswapV2Router02(_router);
    }

    // Set the emission timeframe
    function setEmissionTimeframe(uint256 _emissionTimeframe) external onlyRole(MANAGER_ROLE) {
        emissionTimeframe = _emissionTimeframe;
    }

    // Approve a token to a spender from this contract
    function approveToken(address _token, address _spender) external onlyRole(MANAGER_ROLE) {
        IERC20(_token).approve(_spender, type(uint256).max);
    }

    // Retrieve PLS
    function withdraw() external onlyRole(MANAGER_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Retrieve tokens
    function withdrawToken(address _token) external onlyRole(MANAGER_ROLE) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }
}
