// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    mapping(address => uint256) private balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        
        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        // we can leverage re-entrancy. We make a flashLoan with all the amount of the pool,
        // in the execute(), we deposit all the amount. The flash pool will not revert, because the
        // balance is still the same, but now we have all the funds in our balances.
        // Once the contract is done, we can call withdraw
        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();
        // this contract have good faith in the receiver, but it should not

        if (address(this).balance < balanceBefore)
            revert RepayFailed();
    }
}
