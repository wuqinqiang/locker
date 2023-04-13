// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


    error PublishFailed();
    error WithdrawFailed();

contract Locker {
    event publishEvent(address _address, uint amount);
    event withdrawEvent(address to, uint amount);

    mapping(address => AddressInfo) public balanceOf;
    uint public totalBalance;

    uint delay;

    address public admin;

    struct AddressInfo {
        uint amount;
        uint startTime;
    }

    // init
    constructor(uint _delay) {
        admin = msg.sender;
        delay = _delay;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller not admin!");
        _;
    }


    function publish(uint amount) public payable returns (bool)   {
        AddressInfo storage info = balanceOf[msg.sender];
        info.amount += amount;
        //first publish set startTime
        if (info.startTime == 0) {
            info.startTime = getBlockTimeStamp();
        }
        totalBalance += amount;
        bool success = payable(address(this)).send(amount);
        if (!success) {
            revert PublishFailed();
        }
        emit publishEvent(msg.sender, amount);
        return true;
    }

    function getBlockTimeStamp() public view returns (uint)  {
        return block.timestamp;
    }


    function withdraw(uint amount) public payable returns (bool)  {
        AddressInfo storage info = balanceOf[msg.sender];

        require(info.startTime + delay >= getBlockTimeStamp(), "The time has not yet come!");

        require(info.amount >= amount, "withdraw too much");

        info.amount -= amount;
        if (info.amount == 0) {
            delete balanceOf[msg.sender];
        }
        totalBalance -= amount;

        bool success = payable(msg.sender).send(amount);
        if (!success) {
            revert WithdrawFailed();
        }

        emit withdrawEvent(msg.sender, amount);

        return true;
    }

    function balance() public view returns (uint)  {
        return balanceOf[msg.sender].amount;
    }

    function GetTotalBalance() public view onlyAdmin returns (uint)   {
        return totalBalance;
    }
}