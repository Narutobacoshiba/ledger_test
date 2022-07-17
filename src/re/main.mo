import Cycles "mo:base/ExperimentalCycles";
import Principal "mo:base/Principal";

actor refunded{
    public type TransferArgs = {
        canister: Principal;
        amount: Nat64;
    };

    type CallbackService = actor{ wallet_send : TransferArgs -> async () };

    public func wallet_balance() : async Nat {
        return Cycles.balance();
    };

    public func acceptCycles() : async () {
        let available = Cycles.available();
        let accepted = Cycles.accept(available);
        assert (accepted == available);
    };

    public func sendCycles() : async () {
        let cs : CallbackService = actor("rwlgt-iiaaa-aaaaa-aaaaa-cai");
        await cs.wallet_send({
            canister = Principal.fromText("r7inp-6aaaa-aaaaa-aaabq-cai");
            amount = 100000000;
        });

    }
};
