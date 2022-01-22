# gogamechain
Go Game on Block Chain

```
Objects:

    Block
        Hash
        Content
            Height:
            Previous block hash:
            Version:
            Time:
            Bits:
            Nounce:
            Miner Public Key:
            Transactions:
                Hash Merkle root

    Transaction
        Hash
        Content
            Root Block Id:
            Expire Blocks:
                Inputs:
                Outputs:
            Data:

    Outputs:
        Hash
        Content:
            Receiver:
            Ammount:

https://en.bitcoin.it/wiki/Transaction

Functions:
    Broadcast Block
    Broadcast Transaction
    Verify Block
    Verify Transaction
```

Sketch

```
    Transaction

    Inputs
    Outputs

    Root Block ID
    Expire Blocks

    Heaviest Chain:
    Max Entropy, Max Frozen (Min Liquidity)
    Max Frozen * Max Entropy

    Double Spending Burn

    Proof of Work
    Proof of Appreciation
    Proof of Bury
    Proof of Flowing
    Proof of Winning a contest
    Block Height Only Offer Once PoB
    PoB of Old Coin
    Paper Scissor Stone
    Anti Monopoly Algorithm
    VDF Proof of Time
```
