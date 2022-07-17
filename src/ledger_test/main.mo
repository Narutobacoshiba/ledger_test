import Ledger    "canister:ledger";
import Prim "mo:⛔";
import Debug     "mo:base/Debug";
import Error     "mo:base/Error";
import Int       "mo:base/Int";
import HashMap   "mo:base/HashMap";
import List      "mo:base/List";
import Nat64     "mo:base/Nat64";
import Principal "mo:base/Principal";
import Time      "mo:base/Time";
import Blob "mo:base/Blob";
import Account   "./Account";
import Array "mo:base/Array";
import Cycles "mo:base/ExperimentalCycles";
import Nat "mo:base/Nat"

actor Self{

    // * MANAGER ICP TOKEN * //
    // Returns the default account identifier of this canister.
    func myAccountId() : Account.AccountIdentifier {
        Account.accountIdentifier(Principal.fromActor(Self), Account.defaultSubaccount())
    };


    // Returns canister's default account identifier as a blob.
    public query func canisterAccount() : async Account.AccountIdentifier {
        myAccountId()
    };


    // Returns current balance on the default account of this canister.
    public func canisterBalance() : async Ledger.Tokens {
        await Ledger.account_balance({ account = myAccountId() })
    };

    // Transfer amout from canister to principal
    public shared({caller}) func transferTo(args : Account.TransferArgs) : async Text{
        let now = Time.now();
        let transfer_args = {
            memo = args.memo;
            from_subaccount = ?Account.defaultSubaccount();
            amount = args.amount;
            fee = args.fee;
            to = Account.accountIdentifier(args.to, Account.defaultSubaccount());
            created_at_time = ?{ timestamp_nanos = Nat64.fromNat(Int.abs(now)) };
        };
        switch(await Ledger.transfer(transfer_args)){
            case(#Ok(idx)){ "transfer successfully on block : " # debug_show(idx) };
            case(#Err(error)){ debug_show(error) };
        }
    };

    // Get Block information
    public func getBlocks(args : Account.GetBlocksArgs) : async Account.QueryBlocksResponse {
        let res = await Ledger.query_blocks(args);
        {
            chain_length=res.chain_length;
            certificate=res.certificate;
            //blocks=res.blocks;
            first_block_index=res.first_block_index;
        }
    };


    // * MANAGER CYCLES * //

    type Callback = shared () -> async ();
    type CallbackService = actor{ acceptCycles : Callback };

    //Internal cycle management
    public func acceptCycles() : async () {
        let available = Cycles.available();
        let accepted = Cycles.accept(available);
        assert (accepted == available);
    };


    let limit = 10_000_000;

    // Get cycle balance
    public func wallet_balance() : async Nat {
        return Cycles.balance();
    };

    public func wallet_receive() : async { accepted: Nat64 } {
        let available = Cycles.available();
        let accepted = Cycles.accept(Nat.min(available, limit));
        { accepted = Nat64.fromNat(accepted) };
    };

    public func transfer(principal : Principal, amount : Nat) : async { refunded : Nat } {
        let cs : CallbackService = actor(Principal.toText(principal));
        Cycles.add(amount);
        await cs.acceptCycles();
        { refunded = Cycles.refunded() };
    };
};
