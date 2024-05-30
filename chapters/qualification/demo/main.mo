actor Counter {
    var counter : Nat = 0;
    var message : Text = "Motoko Bootcamp will become the best Web3 bootcamp in the world!";
    let name : Text = "Salman";

    public func setMessage(newMessage : Text) : async () {
        message := newMessage;
    };
    public query func getMessage() : async Text {
        return message;
    };
    public query func getName() : async Text {
        return name;
    };

    public func setCounter(newCounter : Nat) : async () {
        counter := newCounter; // We assign a new value to the counter variable based on the provided argument
        return;
    };

    public func incrementCounter() : async () {
        counter += 1; // We increment the counter by one
        return;
    };

    public query func getCounter() : async Nat {
        return counter;
    };
}