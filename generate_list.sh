#!/bin/bash

TELEGRAM_AUTH_TOKEN=5077327159:AAG79qEO5m3DgXtmzZj7UXLiVOdp-ryVHZU
TELEGRAM_CHAT_ID=-697908946

curl_w() {
curl \
–retry-connrefused \
-sf "$@"
}

send_message() {
curl_w -X POST "https://api.telegram.org/bot${TELEGRAM_AUTH_TOKEN}/sendMessage" \
-H "Content-Type: application/json" \
-d "{\"chat_id\": \"${TELEGRAM_CHAT_ID}\", \"text\": \"${*}\", \"disable_notification\": false}"
}

mainnet_url="https://eth-rpc.gateway.pokt.network/"
goerli_url="https://eth-goerli-rpc.gateway.pokt.network/"
harmony_url="https://harmony-0-rpc.gateway.pokt.network"
fuse_url="https://fuse-rpc.gateway.pokt.network"
gnosis_url="https://xdai-rpc.gateway.pokt.network"
polygon_url="https://poly-rpc.gateway.pokt.network"

verification_endpoint() {
    case $1 in
	1)
	    echo -n $mainnet_url
	    ;;
	5)
	    echo -n $goerli_url
	    ;;
	137)
	    echo -n $polygon_url
	    ;;
	100)
	    echo -n $gnosis_url
	    ;;
	1666600000)
	    echo -n $harmony_url
	    ;;
	122)
	    echo -n $fuse_url
	    ;;
	*)
	    exit 0
    esac    
}

test_archive_call() {
    # contract_address owner_or_deployer_address creation_block_hex endpoint_url
    calldata="{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\": \"$1\", \"data\": \"0x70a08231000000000000000000000000$(echo $2 | sed s/0x//g)\"},\"$3\"],\"id\":1}"
    #echo "$4 $calldata" 
    error=$(curl -s -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\": \"$1\", \"data\": \"0x70a08231000000000000000000000000$(echo $2 | sed s/0x//g)\"},\"$3\"],\"id\":1}" $4 | jq '.error .code')
    #echo "archive_error: $error"
    
    case $error in
	-32000)
	    echo "false"
	    ;;
	-32001)
	    echo "false"
	    ;;
	-32002)
	    echo "false"
	    ;;	
	*)
	    echo "true"
	    ;;
    esac
}

archive_verification() {
    #those are addresses that received a balance in a genesis transaction copied from the list of transactions in block 0 from the block explorer
    case $1 in
	1)
	    test_archive_call 0xdac17f958d2ee523a2206206994597c13d831ec7 0x36928500Bc1dCd7af6a2B4008875CC336b927D57 0x46B87C $2
	    ;;
	5)
	    test_archive_call 0x7af963cf6d228e564e2a0aa0ddbf06210b38615d 0x0402c3407dcbd476c3d2bbd80d1b375144baf4a2 0x233C8 $2
	    ;;
	137)
	    test_archive_call 0x2791bca1f2de4661ed88a30c99a7a9449aa84174 0xdcfae11c70f1575fab9d6bd389a6188ae5524a56 0x4C8057 $2
	    ;;
	100)
	    test_archive_call 0x75df5af045d91108662d8080fd1fefad6aa0bb59 0x87533bfd390c6d11afd8df1a8c095657e0eeed0d 0xB13A2E $2
	    ;;
	1666600000)
	    test_archive_call 0xcF664087a5bB0237a0BAd6742852ec6c8d69A27a 0xf9E7eA064716Edd7Cccb04A79c993109ff5aa907 0x53A2DD $2
	    ;;
	122)
	    echo -n "false"
	    ;;
	*)
	    echo "can not find $1 $2"
	    exit 0
    esac    
}

shopt -s extglob
FILES="endpoints/!(*~)"
first=1
for f in $FILES
do
  #echo "Processing $(basename $f) file..."
  # take action on each file. $f store current file name
  hostname=$(basename $f)
  pathes=$(cat $f)
  for path in $pathes
  do
      [[ $path =~ ^#.* ]] && continue
      url="https://$hostname/$path"

      response=$(curl --location $url --silent --request POST  --header 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[],\"id\":83}")

      case $response in
	  404*)
	      continue
	      ;;
	  *)
	      chain=$(echo $response | jq '.result' | bc)
      esac
      
      syncing=$(curl --location $url --silent --request POST  --header 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":83}" | jq '.result')
      #echo "$url is syncing: $syncing"

      case $syncing in
	  false)
	      #echo "$path is not syncing"
	      include="true"
	      ;;
	  *)
	      #send_message "$path is still syncing on $hostname"
	      continue
	      ;;
      esac
      
      chain_id=$(echo "$((16#$(echo ${chain#'0x'})))")
      rpc_bh_hex=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $url | jq -r '.result')
      rpc_bh=$(echo $((16#`echo $rpc_bh_hex | sed s/0x//g`)))
      ref_url=$(verification_endpoint $chain_id)
      ref_bh=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $ref_url | echo $((16#`jq -r '.result' | sed s/0x//g`)))

      if [ $rpc_bh -ge $((ref_bh)) ]
      then
	  #echo "$path is in sync at $rpc_bh_hex"
	  include="true"
      else
	  #echo "$path is out of sync on $hostname: $rpc_bh / $ref_bh"
	  #echo " "
	  #send_message "$path is out of sync on $hostname: $rpc_bh / $ref_bh"
	  include="false"
      fi

      trace_call_error=$(curl -s -X POST -H "Content-Type: application/json" --data "{\"method\":\"trace_filter\",\"params\":[{\"fromBlock\":\"$rpc_bh_hex\"}],\"id\":1,\"jsonrpc\":\"2.0\"}" $url | jq '.error .code')


      #echo "trace_error: $trace_call_error"

      case $trace_call_error in
	  -32601)
	  #echo "$path doesn't support trace calls"
	      traces=false
	      ;;
	  -32600)
	      #echo "$path doesn't support trace calls"
	      traces=false
	      ;;
	  *)
	      traces=true
	      #echo "$path is fine with traces"
	      ;;
      esac


      is_archive=$(archive_verification $chain_id $url)

      #echo "$url is archive: $is_archive"
      
      case $is_archive in
	  true)
	      #echo "$path can do archive calls"
	      archive="true"
	      ;;
	  false)
	      #echo "$path is not archive"
	      archive="false"
	      ;;
      esac
      
      #echo "$url Blockheight: $rpc_bh ($ref_bh)"
      
      case $include in
	  true)
	      case $first in
		  0)
		      echo -n ","
		      ;;
		  1)
		      echo -n ""
		      ;;
	      esac
	      case $archive in
		  true)
		      case $traces in
			  true)
			      echo -n "https://$hostname/$path#$chain_id;archive;trace"
			      echo -n ",wss://$hostname/$path#$chain_id;archive;trace"
			      ;;
			  false)
			      echo -n "https://$hostname/$path#$chain_id;archive"
			      echo -n ",wss://$hostname/$path#$chain_id;archive"
			      ;;
		      esac
		      ;;
		  false)
		      echo -n "https://$hostname/$path#$chain_id"
		      echo -n ",wss://$hostname/$path#$chain_id"
		      ;;
	      esac
	      ;;
	  false)
	      echo -n ""
	      ;;
      esac

      first=0
      #echo "$url has chain id $chain_id"
  done
done
