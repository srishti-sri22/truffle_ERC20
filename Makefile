BUILD = forge build
TEST = forge test
CLEAN = forge clean
DEPLOY = forge script

ANVIL_NETWORK = anvil
SEPOLIA_NETWORK = sepolia
MAINNET_NETWORK = mainnet

.PHONY: all build test clean deploy-anvil deploy-sepolia deploy-mainnet

all: build test

build:
	$(BUILD)

test:
	$(TEST)

clean:
	$(CLEAN)

deploy-anvil:
	$(DEPLOY) script/DeployAll.s.sol:DeployAll --fork-url $(RPC_URL) --broadcast

deploy-sepolia:
	$(DEPLOY) script/DeployAll.s.sol:DeployAll --rpc-url $(RPC_SEPOLIA) --private-key $(PRIVATE_KEY) --broadcast

deploy-mainnet:
	$(DEPLOY) script/DeployAll.s.sol:DeployAll --rpc-url $(RPC_MAINNET) --private-key $(PRIVATE_KEY) --broadcast
