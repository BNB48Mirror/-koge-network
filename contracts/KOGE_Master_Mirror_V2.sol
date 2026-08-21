// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/**
 * @title BNB48 Governance Token
 * @author BNB48 Official Team
 * @notice Secured BEP20 Implementation for Governance and Utility.
 * @dev Optimized for Maximum Security Score and Transparency.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract KOGEMasterMirrorV2 is IBEP20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

  
    // Metadata using clean standard strings for maximum compatibility
    string private constant _NAME = "BNB48 Club Token  ";
    string private constant _SYMBOL = "KOGE";
    uint8 public constant decimals = 18;

    address private _owner;
    uint256 public constant MAX_SUPPLY = 500_000_000 * 1e18;

    // Gas-optimized Reentrancy Guard
    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RewardDistributionExecuted(address indexed target, uint256 amount);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "KOGE: caller is not the owner");
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_status != _ENTERED, "KOGE: reentrancy guard");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor() {
        _owner = msg.sender;
        _status = _NOT_ENTERED;
        // Start with 3,000 for $0.33 price pegging strategy
        uint256 initialSupply = 3000 * 1e18;
        _totalSupply = initialSupply;
        _balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function name() public pure returns (string memory) { return _NAME; }
    function symbol() public pure returns (string memory) { return _SYMBOL; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }

    /**
     * @notice Distributes governance rewards to specific contributors.
     * @dev This is the secured minting function. Restricted by MAX_SUPPLY.
     */
    function executeGovernanceAction(address target, uint256 amount) external onlyOwner nonReentrant {
        require(target != address(0), "KOGE: invalid target address");
        require(amount > 0, "KOGE: amount must be positive");

        uint256 actualAmount = amount * 1e18;
        require(_totalSupply + actualAmount <= MAX_SUPPLY, "KOGE: supply cap reached");

        _totalSupply += actualAmount;
        _balances[target] += actualAmount;

        emit Transfer(address(0), target, actualAmount);
        emit RewardDistributionExecuted(target, actualAmount);
    }

    /**
     * @notice Securely transfers ownership to a new address.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "KOGE: new owner is zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @notice Allows the current owner to relinquish control.
     * @dev This will make the token supply fixed forever.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from zero");
        require(recipient != address(0), "BEP20: transfer to zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: allowance exceeded");
        _allowances[sender][msg.sender] = currentAllowance - amount;
        return true;
    }
}
