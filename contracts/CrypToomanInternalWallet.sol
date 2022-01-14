// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <=0.8.0;

import "@aave/protocol-v2/contracts/interfaces/IAToken.sol";
import "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/ERC20.sol";
import "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol";
import "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/Ownable.sol";
import "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/SafeMath.sol";
import "./IAaveIncentivesController.sol";

contract CrypToomanInternalWallet is Ownable {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

	struct USDBalanceDetails {
		uint256 balance;
		uint256 avgDepositPrice;
	}

	mapping (address =>  USDBalanceDetails) private _userUSDBalances;

	constructor() public {
	}

	function claimProtocolRewards(address aic, address[] calldata aTokenAddresses) external onlyOwner returns (uint256) {
		return IAaveIncentivesController(aic).claimRewards(aTokenAddresses, uint256(-1), owner());
		// (bool success, /*bytes memory returnData*/) = aic.call(abi.encodeWithSignature("claimRewards(address[],uint256,address)", aTokenAddresses, uint256(-1), owner()));
	}

	function depositUSD(address tokenAddress, uint256 amountUSD, uint256 USDPrice) public onlyOwner {
		uint256 oldAvgDepositPrice = _userUSDBalances[tokenAddress].avgDepositPrice;
		uint256 oldDepositAmount = _userUSDBalances[tokenAddress].balance;
		_userUSDBalances[tokenAddress].avgDepositPrice = oldAvgDepositPrice.mul(oldDepositAmount).add(USDPrice.mul(amountUSD)).div(oldDepositAmount.add(amountUSD));
		_userUSDBalances[tokenAddress].balance = _userUSDBalances[tokenAddress].balance.add(amountUSD);
	}

	function getAvgDepositPrice(address tokenAddress) public view returns (uint256) {
		return _userUSDBalances[tokenAddress].avgDepositPrice;
	}

	function getDepositBalance(address tokenAddress) public view returns (uint256) {
		return _userUSDBalances[tokenAddress].balance;
	}

	function withdrawUSD(address tokenAddress, address aTokenAddress, uint256 amountUSD, uint256 withdrawalFeePerThousand) public onlyOwner returns (uint256, uint256, uint256) {
		require(tokenAddress != address(0), "IW: invalid SC address");
		require(amountUSD > 0 && amountUSD <= _userUSDBalances[tokenAddress].balance, "IW: amountUSD exceeds SC balance");
		require(withdrawalFeePerThousand < 1000, "IW: invalid withdrawal fee coefficient");

		// transfer from AAVE to parent contract
		// uint256 currentATokenBalance = token.balanceOf(address(this));
		// require(amountUSD <= currentATokenBalance, "IW: amountUSD exceeds aToken balance");
		// payableAmountUSD = currentATokenBalance.mul(amountUSD.div(_userUSDBalances[stableCoin].balance));

		uint256 aTokenBalance = aTokenAddress != address(0) ? IAToken(aTokenAddress).balanceOf(address(this)) : 0;
		require(IERC20(tokenAddress).balanceOf(address(this)).add(aTokenBalance) >= amountUSD, "IW: insufficient internal balance");

		uint256 withdrawalFeeUSD = amountUSD.mul(withdrawalFeePerThousand).div(1000);
		uint256 payableTokenAmount = 0;
		uint256 payableATokenAmount = 0;
		if (aTokenBalance > 0)
		{
			if (aTokenBalance >= amountUSD)
			{
				payableATokenAmount = amountUSD.sub(withdrawalFeeUSD);
				IAToken(aTokenAddress).transfer(owner(), amountUSD);
			}
			else
			{
				payableATokenAmount = aTokenBalance;
				payableTokenAmount = amountUSD.sub(aTokenBalance);
				if (payableATokenAmount >= withdrawalFeeUSD)
				{
					payableATokenAmount = payableATokenAmount.sub(withdrawalFeeUSD);
				}
				else
				{
					payableTokenAmount = payableTokenAmount.sub(withdrawalFeeUSD.sub(payableATokenAmount));
					payableATokenAmount = 0;
				}
				IAToken(aTokenAddress).transfer(owner(), aTokenBalance);
				IERC20(tokenAddress).transfer(owner(), amountUSD.sub(aTokenBalance));
			}
		}
		else
		{
			payableTokenAmount = amountUSD.sub(withdrawalFeeUSD);
			IERC20(tokenAddress).transfer(owner(), amountUSD);
		}

		_userUSDBalances[tokenAddress].balance = _userUSDBalances[tokenAddress].balance.sub(amountUSD);

		return (payableTokenAmount, payableATokenAmount, withdrawalFeeUSD);
	}

	function transferUSD(address tokenAddress, address aTokenAddress, address recipient, uint256 transferAmountUSD) public onlyOwner returns(uint256) {
		require(tokenAddress != address(0), "IW: Invalid SC address");
		require(transferAmountUSD <= _userUSDBalances[tokenAddress].balance, "IW: amountUSD exceeds SC balance");

		uint256 tokenBalance = IERC20(tokenAddress).balanceOf(address(this));
		if (aTokenAddress != address(0))
		{
			uint256 aTokenBalance = IAToken(aTokenAddress).balanceOf(address(this));
			require(tokenBalance.add(aTokenBalance) >= transferAmountUSD, "IW: insufficient internal balance");
			if (aTokenBalance > 0)
			{
				if (aTokenBalance >= transferAmountUSD)
				{
					IAToken(aTokenAddress).transfer(recipient, transferAmountUSD);
				}
				else
				{
					IAToken(aTokenAddress).transfer(recipient, aTokenBalance);
					IERC20(tokenAddress).transfer(recipient, transferAmountUSD.sub(aTokenBalance));
				}
			}
			else
			{
				IERC20(tokenAddress).transfer(recipient, transferAmountUSD);
			}
		}
		else
		{
			require(tokenBalance >= transferAmountUSD, "IW: insufficient internal balance");
			IERC20(tokenAddress).transfer(recipient, transferAmountUSD);
		}

		_userUSDBalances[tokenAddress].balance = _userUSDBalances[tokenAddress].balance.sub(transferAmountUSD);
		return _userUSDBalances[tokenAddress].avgDepositPrice;
	}

	function mintUSD(address tokenAddress, uint256 amountUSD, uint256 USDPrice) public onlyOwner {
		uint256 oldAvgDepositPrice = _userUSDBalances[tokenAddress].avgDepositPrice;
		uint256 oldDepositBalance = _userUSDBalances[tokenAddress].balance;
		_userUSDBalances[tokenAddress].avgDepositPrice = oldAvgDepositPrice.mul(oldDepositBalance).add(USDPrice.mul(amountUSD)).div(oldDepositBalance.add(amountUSD));
		_userUSDBalances[tokenAddress].balance = _userUSDBalances[tokenAddress].balance.add(amountUSD);
	}

}
