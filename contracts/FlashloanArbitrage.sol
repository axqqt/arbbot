// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FlashloanArbitrage is FlashLoanSimpleReceiverBase, Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Router02 public sushiswapRouter;

    // Mapping to store supported exchanges
    mapping(address => bool) public supportedExchanges;

    event ArbitrageExecuted(address asset, uint256 amount, uint256 profit);
    event ExchangeAdded(address exchange);
    event ExchangeRemoved(address exchange);

    constructor(
        address _addressProvider,
        address _uniswapRouter,
        address _sushiswapRouter
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) Ownable(msg.sender) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        sushiswapRouter = IUniswapV2Router02(_sushiswapRouter);

        // Add supported exchanges
        supportedExchanges[_uniswapRouter] = true;
        supportedExchanges[_sushiswapRouter] = true;
    }

    function executeArbitrage(address asset, uint256 loanAmount) external onlyOwner {
        address receiverAddress = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            loanAmount,
            params,
            referralCode
        );
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address,
        bytes memory
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Caller must be POOL");

        uint256 amountOutUniswap = getAmountOut(uniswapRouter, asset, amount);
        uint256 amountOutSushiswap = getAmountOut(sushiswapRouter, asset, amount);

        uint256 profit;
        if (amountOutUniswap > amountOutSushiswap) {
            profit = performTrade(sushiswapRouter, uniswapRouter, asset, amount);
        } else if (amountOutSushiswap > amountOutUniswap) {
            profit = performTrade(uniswapRouter, sushiswapRouter, asset, amount);
        }

        uint256 totalDebt = amount + premium;
        IERC20(asset).approve(address(POOL), totalDebt);
        
        emit ArbitrageExecuted(asset, amount, profit);

        return true;
    }

    function getAmountOut(
        IUniswapV2Router02 router,
        address token,
        uint256 amountIn
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();

        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function performTrade(
        IUniswapV2Router02 buyRouter,
        IUniswapV2Router02 sellRouter,
        address token,
        uint256 amountIn
    ) internal returns (uint256) {
        IERC20(token).approve(address(buyRouter), amountIn);

        address[] memory buyPath = new address[](2);
        buyPath[0] = buyRouter.WETH();
        buyPath[1] = token;

        uint256[] memory amounts = buyRouter.swapExactTokensForTokens(
            amountIn,
            0,
            buyPath,
            address(this),
            block.timestamp
        );

        uint256 boughtAmount = amounts[1];
        IERC20(token).approve(address(sellRouter), boughtAmount);

        address[] memory sellPath = new address[](2);
        sellPath[0] = token;
        sellPath[1] = sellRouter.WETH();

        uint256[] memory soldAmounts = sellRouter.swapExactTokensForTokens(
            boughtAmount,
            0,
            sellPath,
            address(this),
            block.timestamp
        );

        uint256 soldAmount = soldAmounts[1];
        return soldAmount > amountIn ? soldAmount - amountIn : 0;
    }

    function withdrawProfits() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No profits to withdraw");
        payable(owner()).transfer(balance);
    }

    function addSupportedExchange(address newExchange) external onlyOwner {
        require(!supportedExchanges[newExchange], "Exchange already supported");
        supportedExchanges[newExchange] = true;
        emit ExchangeAdded(newExchange);
    }

    function removeSupportedExchange(address exchange) external onlyOwner {
        require(supportedExchanges[exchange], "Exchange not supported");
        supportedExchanges[exchange] = false;
        emit ExchangeRemoved(exchange);
    }

    receive() external payable {}
}