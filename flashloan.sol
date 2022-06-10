pragma solidity ^0.8.1;

import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "https://github.com/Nnamdichukwu/flashloan/blob/main/IWeth.sol";
import "https://github.com/Nnamdichukwu/flashloan/blob/main/IUniswapV2Router02.sol";

contract Flashloan is FlashLoanReceiverBase {
    // IKyberNetworkProxy kyber;
    IUniswapV2Router02 uniswap ;
   IWETH weth;
    IERC20 dai;
    address funder;

    constructor(address _addressProvider) FlashLoanReceiverBase(_addressProvider) public {
        funder = _addressProvider;
    }

function  addresses() public{
    uniswap = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    weth = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    dai = IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);
}
function returnContractAddress() public view returns(address){
    return address(this);

}
fallback() external payable{}

function sendContractMoney() public payable{
    payable(address(this)).transfer(msg.value);
}

function buyDaiOnUniswap() public payable {

        
        uint amountOutMin = msg.value;
          //Buy ETH on Uniswap
          dai.approve(address(uniswap),  dai.balanceOf(funder)); 
          address[] memory path = new address[](2);
          path[1] = address(dai);
          path[0] = address(weth);
        //  uint[] memory minOuts = uniswap.getAmountsOut( dai.balanceOf(address(this)), path); 
          uniswap.swapETHForExactTokens{value: msg.value}(
            amountOutMin, 
            path, 
           address(this),
            block.timestamp
          );
}
function sellDaiForEthOnUniswap() public  {
        // uint amountOutMin = 1000000000000000 wei;
          //Buy ETH on Uniswap
          dai.approve(address(uniswap),  dai.balanceOf(address(this))); 

          address[] memory path = new address[](2);
          path[0] = address(dai);
          path[1] = address(weth);
          uint[] memory minOuts = uniswap.getAmountsOut( dai.balanceOf(address(this)), path);
          uniswap.swapExactTokensForETH(
              dai.balanceOf(address(this)), 
             minOuts[1],
           
            path,
            funder,
     block.timestamp
          );

}
    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(funder, _reserve), "Invalid balance, was the flashLoan successful?");

        //
        // Your logic goes here.
        // !! Ensure that *this contract* has enough of `_reserve` funds to payback the `_fee` !!
        //

        uint totalDebt = _amount + _fee ;
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    /**
        Flash loan 1000000000000000000 wei (1 ether) worth of `_asset`
     */
    function flashloan(address _asset) public onlyOwner {
        bytes memory data = "";
        uint amount = 10000000000000000 wei;

        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), _asset, amount, data);
    }
    function depositWeth() public payable{
     weth.deposit{value: msg.value}();
    }

}
