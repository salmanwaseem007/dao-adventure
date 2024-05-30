actor MotivationLetter {

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
    // Task #1:
    // Define an immutable variable `name` of type `Text`.
    // Initialize it with your name.

    // Task #2:
    // Define a mutable variable `message` of type `Text`.
    // Initialize it with your project goals on the Internet Computer.

    // Task #3:
    // Create an update function `setMessage` that takes `newMessage` of type `Text` as an argument
    // and updates the `message` variable with the argument's value.

    // Task #4:
    // Define a query function `getMessage` that returns the current value of the `message` variable.

    // Task #5:
    // Define a query function `getName` that returns the current value of the `name` variable.

    // Task #6:
    // Deploy your canister and submit the Canister ID on motokobootcamp.com.
    // Gain access to our secret OpenChat community and have your name included on the Legacy Scroll forever.

    
};