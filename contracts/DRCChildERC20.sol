// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ChildToken.sol";
import "./misc/IParentToken.sol";

contract DRCChildERC20 is ChildToken, ERC20 {
    event Deposit(address indexed token, address indexed from, uint256 amount, uint256 input1, uint256 output1);

    event Withdraw(address indexed token, address indexed from, uint256 amount, uint256 input1, uint256 output1);

    event LogTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 input1,
        uint256 input2,
        uint256 output1,
        uint256 output2
    );

    constructor(
        address _owner,
        address _token,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20(_name, _symbol) {
        require(_token != address(0x0) && _owner != address(0x0));
        parentOwner = _owner;
        token = _token;
        _setupDecimals(_decimals);
    }

    function setParent(address _parent) public isParentOwner {
        require(_parent != address(0x0));
        parent = _parent;
    }

    /**
     * Deposit tokens
     *
     * @param user address for address
     * @param amount token balance
     */
    function deposit(address user, uint256 amount) public onlyOwner {
        // check for amount and user
        require(amount > 0 && user != address(0x0));

        // input balance
        uint256 input1 = balanceOf(user);

        // increase balance
        _mint(user, amount);

        // deposit events
        emit Deposit(token, user, amount, input1, balanceOf(user));
    }

    /**
     * Withdraw tokens
     *
     * @param amount tokens
     */
    function withdraw(uint256 amount) public payable {
        address user = msg.sender;
        // input balance
        uint256 input = balanceOf(user);

        // check for amount
        require(amount > 0 && input >= amount);

        // decrease balance
        _burn(user, amount);

        // withdraw event
        emit Withdraw(token, user, amount, input, balanceOf(user));
    }

    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param to Address of token receiver.
    /// @param value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address to, uint256 value) public override returns (bool) {
        if (parent != address(0x0) && !IParentToken(parent).beforeTransfer(msg.sender, to, value)) {
            return false;
        }
        return _transferFrom(msg.sender, to, value);
    }

    function allowance(address, address) public view override returns (uint256) {
        revert("Disabled feature");
    }

    function approve(address, uint256) public override returns (bool) {
        revert("Disabled feature");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public override returns (bool) {
        revert("Disabled feature");
    }

    function transferWithSig(
        bytes calldata sig,
        uint256 amount,
        bytes32 data,
        uint256 expiration,
        address to
    ) external returns (address from) {
        require(amount > 0);
        require(expiration == 0 || block.number <= expiration, "Signature is expired");

        bytes32 dataHash = getTokenTransferOrderHash(msg.sender, amount, data, expiration);
        require(disabledHashes[dataHash] == false, "Sig deactivated");
        disabledHashes[dataHash] = true;

        from = ecrecovery(dataHash, sig);
        _transferFrom(from, address(uint160(to)), amount);
    }

    /// @param from Address from where tokens are withdrawn.
    /// @param to Address to where tokens are sent.
    /// @param value Number of tokens to transfer.
    /// @return Returns success of function call.
    function _transferFrom(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        uint256 input1 = this.balanceOf(from);
        uint256 input2 = this.balanceOf(to);
        _transfer(from, to, value);
        emit LogTransfer(token, from, to, value, input1, input2, this.balanceOf(from), this.balanceOf(to));
        return true;
    }
}