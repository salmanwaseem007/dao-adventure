import Result "mo:base/Result";
import HashMap "mo:base/HashMap";
import TrieMap "mo:base/TrieMap";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Nat64 "mo:base/Nat64";
import Iter "mo:base/Iter";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Types "types";
actor {
    // For this level we need to make use of the code implemented in the previous projects.
    // The voting system will make use of previous data structures and functions.

    /////////////////
    //   TYPES    //
    ///////////////
    type Member = Types.Member;
    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type HashMap<K, V> = Types.HashMap<K, V>;
    type Proposal = Types.Proposal;
    type ProposalContent = Types.ProposalContent;
    type ProposalId = Types.ProposalId;
    type Vote = Types.Vote;
    type DAOStats = Types.DAOStats;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;

    /////////////////
    // PROJECT #1 //
    ///////////////
    let goals = Buffer.Buffer<Text>(0);
    let name = "RDX";
    var manifesto = "RDX manifesto";

    public shared query func getName() : async Text {
        return name;
    };

    public shared query func getManifesto() : async Text {
        return manifesto;
    };

    public func setManifesto(newManifesto : Text) : async () {
        manifesto := newManifesto;
        return;
    };

    public func addGoal(newGoal : Text) : async () {
        goals.add(newGoal);
        return;
    };

    public shared query func getGoals() : async [Text] {
        Buffer.toArray(goals);
    };

    /////////////////
    // PROJECT #2 //
    ///////////////
    let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);

    public shared ({ caller }) func addMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                members.put(caller, member);
                return #ok();
            };
            case (?member) {
                return #err("Member already exists");
            };
        };
    };

    public shared ({ caller }) func updateMember(member : Member) : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                members.put(caller, member);
                return #ok();
            };
        };
    };

    public shared ({ caller }) func removeMember() : async Result<(), Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                members.delete(caller);
                return #ok();
            };
        };
    };

    public query func getMember(p : Principal) : async Result<Member, Text> {
        switch (members.get(p)) {
            case (null) {
                return #err("Member does not exist");
            };
            case (?member) {
                return #ok(member);
            };
        };
    };

    public query func getAllMembers() : async [Member] {
        return Iter.toArray(members.vals());
    };

    public query func numberOfMembers() : async Nat {
        return members.size();
    };

    /////////////////
    // PROJECT #3 //
    ///////////////
    let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

    public query func tokenName() : async Text {
        return "RDX";
    };

    public query func tokenSymbol() : async Text {
        return "RDX";
    };

    public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance + amount);
        return #ok();
    };

    public func burn(owner : Principal, amount : Nat) : async Result<(), Text> {
        let balance = Option.get(ledger.get(owner), 0);
        if (balance < amount) {
            return #err("Insufficient balance to burn");
        };
        ledger.put(owner, balance - amount);
        return #ok();
    };

    func _burn(owner : Principal, amount : Nat) : () {
        let balance = Option.get(ledger.get(owner), 0);
        ledger.put(owner, balance - amount);
        return;
    };

    public shared ({ caller }) func transfer(from : Principal, to : Principal, amount : Nat) : async Result<(), Text> {
        let balanceFrom = Option.get(ledger.get(from), 0);
        let balanceTo = Option.get(ledger.get(to), 0);
        if (balanceFrom < amount) {
            return #err("Insufficient balance to transfer");
        };
        ledger.put(from, balanceFrom - amount);
        ledger.put(to, balanceTo + amount);
        return #ok();
    };

    public query func balanceOf(owner : Principal) : async Nat {
        return (Option.get(ledger.get(owner), 0));
    };

    public query func totalSupply() : async Nat {
        var total = 0;
        for (balance in ledger.vals()) {
            total += balance;
        };
        return total;
    };
    /////////////////
    // PROJECT #4 //
    ///////////////
    var nextProposalId : Nat64 = 0;
    let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat64.equal, Nat64.toNat32);

    public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
        switch (members.get(caller)) {
            case (null) {
                return #err("The caller is not a member - cannot create a proposal");
            };
            case (?member) {
                let balance = Option.get(ledger.get(caller), 0);
                if (balance < 1) {
                    return #err("The caller does not have enough tokens to create a proposal");
                };
                // Create the proposal and burn the tokens
                let proposal : Proposal = {
                    id = nextProposalId;
                    content;
                    creator = caller;
                    created = Time.now();
                    executed = null;
                    votes = [];
                    voteScore = 0;
                    status = #Open;
                };
                proposals.put(nextProposalId, proposal);
                nextProposalId += 1;
                _burn(caller, 1);
                return #ok(nextProposalId - 1);
            };
        };
    };

    public query func getProposal(proposalId : ProposalId) : async ?Proposal {
        return proposals.get(proposalId);
    };

    public shared ({ caller }) func voteProposal(proposalId : ProposalId, vote : Vote) : async Result<(), Text> {
        // Check if the caller is a member of the DAO
        switch (members.get(caller)) {
            case (null) {
                return #err("The caller is not a member - canno vote one proposal");
            };
            case (?member) {
                // Check if the proposal exists
                switch (proposals.get(proposalId)) {
                    case (null) {
                        return #err("The proposal does not exist");
                    };
                    case (?proposal) {
                        // Check if the proposal is open for voting
                        if (proposal.status != #Open) {
                            return #err("The proposal is not open for voting");
                        };
                        // Check if the caller has already voted
                        if (_hasVoted(proposal, caller)) {
                            return #err("The caller has already voted on this proposal");
                        };
                        let balance = Option.get(ledger.get(caller), 0);
                        let multiplierVote = switch (vote.yesOrNo) {
                            case (true) { 1 };
                            case (false) { -1 };
                        };
                        let newVoteScore = proposal.voteScore + balance * multiplierVote;
                        var newExecuted : ?Time.Time = null;
                        let newVotes = Buffer.fromArray<Vote>(proposal.votes);
                        let newStatus = if (newVoteScore >= 100) {
                            #Accepted;
                        } else if (newVoteScore <= -100) {
                            #Rejected;
                        } else {
                            #Open;
                        };
                        switch (newStatus) {
                            case (#Accepted) {
                                _executeProposal(proposal.content);
                                newExecuted := ?Time.now();
                            };
                            case (_) {};
                        };
                        let newProposal : Proposal = {
                            id = proposal.id;
                            content = proposal.content;
                            creator = proposal.creator;
                            created = proposal.created;
                            executed = newExecuted;
                            votes = Buffer.toArray(newVotes);
                            voteScore = newVoteScore;
                            status = newStatus;
                        };
                        proposals.put(proposal.id, newProposal);
                        return #ok();
                    };
                };
            };
        };
    };

    func _hasVoted(proposal : Proposal, member : Principal) : Bool {
        return Array.find<Vote>(
            proposal.votes,
            func(vote : Vote) {
                return vote.member == member;
            },
        ) != null;
    };

    func _executeProposal(content : ProposalContent) : () {
        switch (content) {
            case (#ChangeManifesto(newManifesto)) {
                manifesto := newManifesto;
            };
            case (#AddGoal(newGoal)) {
                goals.add(newGoal);
            };
        };
        return;
    };

    public query func getAllProposals() : async [Proposal] {
        return Iter.toArray(proposals.vals());
    };

    /////////////////
    // PROJECT #5 //
    ///////////////
    let logo : Text = "RDX";

    func _getWebpage() : Text {
        var webpage = "<style>" #
        "body { text-align: center; font-family: Arial, sans-serif; background-color: #f0f8ff; color: #333; }" #
        "h1 { font-size: 3em; margin-bottom: 10px; }" #
        "hr { margin-top: 20px; margin-bottom: 20px; }" #
        "em { font-style: italic; display: block; margin-bottom: 20px; }" #
        "ul { list-style-type: none; padding: 0; }" #
        "li { margin: 10px 0; }" #
        "li:before { content: '👉 '; }" #
        "svg { max-width: 150px; height: auto; display: block; margin: 20px auto; }" #
        "h2 { text-decoration: underline; }" #
        "</style>";

        webpage := webpage # "<div><h1>" # name # "</h1></div>";
        webpage := webpage # "<em>" # manifesto # "</em>";
        webpage := webpage # "<div>" # logo # "</div>";
        webpage := webpage # "<div><?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' id='Layer_1' data-name='Layer 1' width='512' height='512' viewBox='0 0 24 24'><path d='M15.5,6c-1.378,0-2.5,1.122-2.5,2.5s1.122,2.5,2.5,2.5,2.5-1.122,2.5-2.5-1.122-2.5-2.5-2.5Zm0,4c-.827,0-1.5-.673-1.5-1.5s.673-1.5,1.5-1.5,1.5,.673,1.5,1.5-.673,1.5-1.5,1.5ZM24,2.5c0-1.378-1.122-2.5-2.514-2.5-4.942,.141-9.444,2.552-13.111,7.001-1.586,.019-3.168,.404-4.585,1.115-2.302,1.155-3.79,3.661-3.79,6.384v.5H5c1.068,0,2.073,.416,2.829,1.171,.755,.756,1.171,1.76,1.171,2.829v5h.5c2.723,0,5.229-1.487,6.384-3.789,.712-1.417,1.096-3,1.115-4.586,4.448-3.667,6.86-8.17,7.001-13.125ZM4.238,9.01c1.034-.519,2.165-.845,3.317-.961-.098,.132-.196,.265-.293,.4-1.553,2.167-2.712,4.684-3.092,5.551H1.019c.166-2.15,1.393-4.074,3.219-4.99Zm10.752,10.752c-.917,1.826-2.84,3.053-4.99,3.219v-3.151c.868-.38,3.384-1.539,5.552-3.092,.135-.097,.268-.194,.4-.292-.116,1.152-.442,2.283-.961,3.317Zm-.021-3.837c-1.803,1.292-3.914,2.325-4.976,2.811-.064-1.236-.576-2.389-1.457-3.271-.882-.882-2.035-1.393-3.271-1.457,.486-1.062,1.519-3.173,2.811-4.976C10.629,5.469,15.033,1.184,21.5,1c.827,0,1.5,.673,1.5,1.486-.184,6.481-4.469,10.885-8.031,13.439ZM1.732,18.732c-.85,.849-1.419,3.881-1.524,4.48l-.124,.703,.703-.124c.599-.105,3.631-.674,4.48-1.524,.472-.472,.732-1.1,.732-1.768s-.26-1.296-.732-1.768c-.943-.944-2.592-.944-3.535,0Zm2.828,2.828c-.386,.386-1.934,.831-3.227,1.106,.275-1.293,.72-2.841,1.106-3.227,.283-.283,.66-.439,1.061-.439s.777,.156,1.061,.439,.439,.66,.439,1.061-.156,.777-.439,1.061Z'/></svg></div>";
        webpage := webpage # "<hr>";
        webpage := webpage # "<h2>Our goals:</h2>";
        webpage := webpage # "<ul>";
        for (goal in goals.vals()) {
            webpage := webpage # "<li>" # goal # "</li>";
        };
        webpage := webpage # "</ul>";
        return webpage;
    };

    public query func getStats() : async DAOStats {
        return ({
            name = name;
            manifesto = manifesto;
            goals = Buffer.toArray(goals);
            members =  Iter.toArray(Iter.map<Member, Text>(members.vals(), func(member : Member) { member.name }));
            logo = logo;
            numberOfMembers = members.size();
        });
    };

    public func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            status_code = 200;
            headers = [("Content-Type", "text/html; charset=UTF-8")];
            body = Text.encodeUtf8(_getWebpage());
            streaming_strategy = null;
        });
    };

};