WELCOME TO MY PROJECT

1) INTRODUCTION
This is a project about a crowdsale like IDO (Initial DEX Offering)
Name: Crowdsale_IDO_ERC20
Developers: 
	Smart Contract: Binh
	Frond-End: An
Details:
	* Description's Project:
	A Pool which is used to buy Token from Investors. All investors are added to a list. 
	They have to wait for Crowdsale is opened, and ClaimTime is opened.
	During the time Crowdsale is opened. They can buy Token (Deposit USDT) and receive those tokens (Claim Token)
	
	* Information about Token is sold:
	Name: HoBiToken
	Symbol: HBT
	Price: 0.1 USDT
	Total Supply: 10,000,000 HBT
	Whitelist amount: 100 investors
	Total Token (available to sell): 500,000 HBT
	Minimum USDT: 200 USDT
	Maximum USDT: 500 USDT	
	OpenTime Crowdsale: 
	CloseTime Crowdsale:
	ReleaseTime Crowdsale:


2) TECHNOLOGY
	Languages: Solidity ver 0.8.0
	Framework: Truffle, Remix

3) Deploy Project
	using Remix.org
	
	Steps by steps ---- setting up deploy

	Step 1: Deploy HoBiToken.sol by address A
	Step 2: Deploy USDT.sol by address B (only for testing, is also address's investor)
	Step 3: Deploy Crowdsale.sol by address A

	owner's address (address A)
		addInvestors ==> transfer

		transfer to: crowdsale contract
		transfer amount: 500000000000000000000000

	usdt's address (address B)
		approve ==> depositUSDT ==> claimTokens

		approve spender: crowdsale contract
		approve amount: 500000000000000000000

		deposit USDT: 500000000000000000000
		


	 

	