# rpc-endpoints

Get your IP whitelisted on StakeSquid PRC servers and enjoy unlimited RPC access to many EVM compatible networks with archive calls and trace support.

Currently supported archive nodes
* Polygon
* Avalanche
* Ethereum
* Gnosis
* Celo
* Arbitrum
* Optimism
* Goerli

All of them except Optimism and Avalanche support trace calls.

```
docker run -e UPSTREAM_RPCS="https://cloudflare-eth.com" -p 127.0.0.1:8545:8545 stakesquid/eth-proxy:latest
```

The UPSTREAM_RPCS variable takes the following format:

UPSTREAM_RPCS="[URL]#[CHAIN_ID][;archive?][;trace?][;receipts?],..."

While it's possible to configure the variable manually it can be auto populated for the stakesquid offer with the provided script.

```
./generate_list.sh
```


To run the local rpc proxy populated with stakesquid upstreams you can use the start script.

```
./start.sh
```

The proxy accepts connections on http://localhost:8545/[CHAIN_ID] as in the following example.

```
curl http://localhost:8545/ \
  -X POST \
  -H "Content-Type: application/json" \
  --data '{"method":"eth_getLogs", "params":[{"address": "0xdAC17F958D2ee523a2206206994597C13D831ec7", "fromBlock": "latest"}],"id":1, "jsonrpc":"2.0"}'
```

Where CHAIN_ID simply defaults to 1 for Ethereum mainnet.

```
curl --location http://locahost:8545/137 --request POST  \
--header 'Content-Type: application/json' \
--data-raw '{
	"jsonrpc":"2.0",
	"method":"web3_clientVersion",
	"params":[],
	"id":1
}'
```

Where CHAIN_ID is 137 for Polygon mainnet. Different upstreams can respond to the same query so the web3_clientVersion will can be different between reequests. The local load balancer will continously monitor the performance of the upstreams for different request methods and try to select the most performant node for answering each query. Batch queries will be split and submmitted via websocket request. eth_getLogs requests will always be submitted via HTTP. The proxy is tested for usage as compagnion for a graph-node indexer.


You can order the complete package via Email from goldberg@stakesquid.com for 100 EUR per month 
* exclusive for TheGraph indexers
* crypto payments welcome 
* no KYC 
* excluding VAT for EU based clients

