import Buffer "mo:base/Buffer";

actor {

    let name : Text = "AppDAO";
    var manifesto : Text  = "AppDAO Manifesto";
    var goals = Buffer.Buffer<Text>(2);

    public shared query func getName() : async Text {
        return name;
    };

    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    public func setManifesto(newManifesto : Text) : async () {
        manifesto:=newManifesto;
    };

    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
    };

    public shared query func getGoals() : async [Text] {
        return Buffer.toArray<Text>(goals);
    };
};