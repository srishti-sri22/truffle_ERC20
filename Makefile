NETWORK ?= sepolia
RPC_URL ?= $${RPC_URL}
PRIVATE_KEY ?= $${PRIVATE_KEY}

OUT_DIR = out/deploy
TOKEN_ADDR_FILE = $(OUT_DIR)/token.addr
FAUCET_ADDR_FILE = $(OUT_DIR)/faucet.addr

.PHONY: all clean token faucet transferall

all: token faucet transferall

token:
	mkdir -p $(OUT_DIR)
	forge script script/DeployToken.s.sol:DeployToken \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--json > $(OUT_DIR)/token.json
	jq -r '.transactions[0].contractAddress' $(OUT_DIR)/token.json > $(TOKEN_ADDR_FILE)
	@echo "Token deployed at:" $$(cat $(TOKEN_ADDR_FILE))

faucet:
	TOKEN_ADDR=$$(cat $(TOKEN_ADDR_FILE))
	forge script script/DeployFaucet.s.sol:DeployFaucet \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--sig "run(address)" $$TOKEN_ADDR \
		--json > $(OUT_DIR)/faucet.json
	jq -r '.transactions[0].contractAddress' $(OUT_DIR)/faucet.json > $(FAUCET_ADDR_FILE)
	@echo "Faucet deployed at:" $$(cat $(FAUCET_ADDR_FILE))

transferall:
	TOKEN_ADDR=$$(cat $(TOKEN_ADDR_FILE))
	FAUCET_ADDR=$$(cat $(FAUCET_ADDR_FILE))
	forge script script/TransferOwnershipToFaucet.s.sol:TransferOwnershipToFaucet \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--sig "run(address,address)" $$TOKEN_ADDR $$FAUCET_ADDR
	@echo "Ownership transferred to faucet"

clean:
	rm -rf $(OUT_DIR)
