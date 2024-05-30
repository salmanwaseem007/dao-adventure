import Result "mo:base/Result";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Types "types";
actor {

    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;

    let _tokenName ="RDX Token";
    let _tokenSymbol ="RDX";
    let ledger: HashMap<Principal, Nat> = HashMap.HashMap(32, Principal.equal, Principal.hash);

    public query func tokenName() : async Text {
        return _tokenName;
    };

    public query func tokenSymbol() : async Text {
        return _tokenSymbol;
    };

    public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
        switch (ledger.get(owner)){
            case(null){
                ledger.put(owner, amount);
            };
            case(?currentAmount){
                ledger.put(owner, currentAmount + amount);
            };
        };

        return #ok();
    };

    public func burn(owner : Principal, amount : Nat) : async Result<(), Text> {
        switch (ledger.get(owner)){
            case(null){
                return #err("account not found");
            };
            case(?currentAmount){
                ledger.put(owner, currentAmount - amount);
            };
        };

        return #ok();
    };

    public shared ({ caller }) func transfer(from : Principal, to : Principal, amount : Nat) : async Result<(), Text> {
        let fromBalance: Nat = Option.get(ledger.get(from), 0);
        let toBalance : Nat= Option.get(ledger.get(to), 0);
        if(fromBalance<=0 or (fromBalance-amount)<=0){
            return #err("Not enough balance in from account");
        };
        
        ledger.put(from, fromBalance - amount);
        ledger.put(to, toBalance + amount);

        return #ok();
    };

    public query func balanceOf(account : Principal) : async Nat {
        switch (ledger.get(account)){
            case(null){
                return 0;
            };
            case(?currentAmount){
                return currentAmount;
            };
        };
    };

    public query func totalSupply() : async Nat {
        var sum=0;
        for(value in ledger.vals()){
            sum+=value;
        };
        return sum;
    };

};