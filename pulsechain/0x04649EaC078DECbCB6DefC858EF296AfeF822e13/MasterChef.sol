// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Token is AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Function Island Yield", "fiYIELD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }
}

contract MasterChef is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Yield
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accYieldPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accYieldPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Yield to distribute per second.
        uint256 lastRewardTime; // Last time that Yield distribution occurs.
        uint256 accYieldPerShare; // Accumulated Yield per share, times 1e12. See below.
    }

    Token public yield;

    // Yield tokens created per second.
    uint256 public yieldPerSecond;

    // set a max Yield per second, which can never be higher than 1 per second
    uint256 public constant maxYieldPerSecond = 1e18;

    uint256 public constant MaxAllocPoint = 4000;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block time when Yield mining starts.
    uint256 public immutable startTime;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(Token _yield, uint256 _yieldPerSecond, uint256 _startTime) {
        yield = _yield;
        yieldPerSecond = _yieldPerSecond;
        startTime = _startTime;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Changes Yield token reward per second, with a cap of maxYield per second
    // Good practice to update pools without messing up the contract
    function setYieldPerSecond(
        uint256 _yieldPerSecond
    ) external onlyRole(MANAGER_ROLE) {
        require(
            _yieldPerSecond <= maxYieldPerSecond,
            "setYieldPerSecond: too much Yield!"
        );

        // This MUST be done or pool rewards will be calculated with new Yield per second
        // This could unfairly punish small pools that dont have frequent deposits/withdraws/harvests
        massUpdatePools();

        yieldPerSecond = _yieldPerSecond;
    }

    function checkForDuplicate(IERC20 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            require(
                poolInfo[_pid].lpToken != _lpToken,
                "add: pool already exists!!!!"
            );
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken
    ) external onlyRole(MANAGER_ROLE) {
        require(_allocPoint <= MaxAllocPoint, "add: too many alloc points!!");

        checkForDuplicate(_lpToken); // ensure you cant add duplicate pools

        massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accYieldPerShare: 0
            })
        );
    }

    // Update the given pool's Yield allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) external onlyRole(MANAGER_ROLE) {
        if (poolInfo[_pid].allocPoint > _allocPoint) {
            require(
                totalAllocPoint - (poolInfo[_pid].allocPoint - _allocPoint) > 0,
                "add: can't set totalAllocPoint to 0!!"
            );
        }
        require(_allocPoint <= MaxAllocPoint, "add: too many alloc points!!");

        massUpdatePools();

        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        if (_to < startTime) {
            return 0;
        }
        return _to - _from;
    }

    // View function to see pending Yield on frontend.
    function pendingYield(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accYieldPerShare = pool.accYieldPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 yieldReward = multiplier
                .mul(yieldPerSecond)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accYieldPerShare = accYieldPerShare.add(
                yieldReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accYieldPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            pool.lastRewardTime,
            block.timestamp
        );
        uint256 yieldReward = multiplier
            .mul(yieldPerSecond)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        yield.mint(address(this), yieldReward);

        pool.accYieldPerShare = pool.accYieldPerShare.add(
            yieldReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for Yield allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accYieldPerShare).div(1e12).sub(
            user.rewardDebt
        );

        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accYieldPerShare).div(1e12);

        if (pending > 0) {
            safeYieldTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accYieldPerShare).div(1e12).sub(
            user.rewardDebt
        );

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accYieldPerShare).div(1e12);

        if (pending > 0) {
            safeYieldTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint oldUserAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.safeTransfer(address(msg.sender), oldUserAmount);
        emit EmergencyWithdraw(msg.sender, _pid, oldUserAmount);
    }

    // Safe Yield transfer function, just in case if rounding error causes pool to not have enough Yield.
    function safeYieldTransfer(address _to, uint256 _amount) internal {
        uint256 yieldBal = yield.balanceOf(address(this));
        if (_amount > yieldBal) {
            yield.transfer(_to, yieldBal);
        } else {
            yield.transfer(_to, _amount);
        }
    }
}
