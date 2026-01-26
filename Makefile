ifneq (,$(wildcard ./.env))
    include .env
    export
endif

BUILD = forge build
TEST = forge test
CLEAN = forge clean
DEPLOY = forge script

ANVIL_NETWORK = anvil
SEPOLIA_NETWORK = sepolia
MAINNET_NETWORK = mainnet 

.PHONY: all build test clean deploy-anvil deploy-sepolia deploy-mainnet verify-sepolia verify-mainnet anvil test-local


test-local: anvil
	$(TEST) --fork-url $(RPC_ANVIL)

deploy-anvil:
	$(DEPLOY) script/deployAll.s.sol:DeployAll --rpc-url $(RPC_ANVIL) --private-key $(ANVIL_PRIVATE_KEY) --broadcast

deploy-sepolia:
	$(DEPLOY) script/deployAll.s.sol:DeployAll --rpc-url $(RPC_SEPOLIA) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY)


deploy-mainnet:
	$(DEPLOY) script/deployAll.s.sol:DeployAll --rpc-url $(RPC_MAINNET) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) --slow


verify-sepolia:
	forge verify-contract --chain-id 11155111 --verifier etherscan --etherscan-api-key $(ETHERSCAN_API_KEY) <CONTRACT_ADDRESS> src/Token.sol:Token

	forge verify-contract --chain-id 11155111 --verifier etherscan --etherscan-api-key $(ETHERSCAN_API_KEY) <CONTRACT_ADDRESS> src/TokenFaucet.sol:TokenFaucet

verify-mainnet:
	forge verify-contract \--chain-id 1 --verifier etherscan --etherscan-api-key $(ETHERSCAN_API_KEY) <CONTRACT_ADDRESS> src/Token.sol:Token

	forge verify-contract --chain-id 1 --verifier etherscan --etherscan-api-key $(ETHERSCAN_API_KEY) <CONTRACT_ADDRESS> src/TokenFaucet.sol:TokenFaucet

