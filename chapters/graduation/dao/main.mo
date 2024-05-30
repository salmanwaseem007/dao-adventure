import Result "mo:base/Result";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Types "types";
actor {

        type Result<A, B> = Result.Result<A, B>;
        type Member = Types.Member;
        type Role = Types.Role;
        type ProposalContent = Types.ProposalContent;
        type ProposalId = Types.ProposalId;
        type Proposal = Types.Proposal;
        type Vote = Types.Vote;
        type HttpRequest = Types.HttpRequest;
        type HttpResponse = Types.HttpResponse;

        // The principal of the Webpage canister associated with this DAO canister (needs to be updated with the ID of your Webpage canister)
        stable let canisterIdWebpage : Principal = Principal.fromText("aaaaa-aa");
        let goals = Buffer.Buffer<Text>(0);
        let name = "RDX";
        var manifesto = "RDX manifesto";
        let members = HashMap.HashMap<Principal, Member>(0, Principal.equal, Principal.hash);
        let ledger = HashMap.HashMap<Principal, Nat>(0, Principal.equal, Principal.hash);

        var nextProposalId : Nat64 = 0;
        let proposals = HashMap.HashMap<ProposalId, Proposal>(0, Nat64.equal, Nat64.toNat32);

        public shared query func getName() : async Text {
                return name;
        };

        public shared query func getManifesto() : async Text {
                return manifesto;
        };

        // Returns the goals of the DAO
        public query func getGoals() : async [Text] {
                Buffer.toArray(goals);
        };

        // Register a new member in the DAO with the given name and principal of the caller
        // Airdrop 10 MBC tokens to the new member
        // New members are always Student
        // Returns an error if the member already exists
        public shared ({ caller }) func registerMember(member : Member) : async Result<(), Text> {
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

        // Get the member with the given principal
        // Returns an error if the member does not exist
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

        // Graduate the student with the given principal
        // Returns an error if the student does not exist or is not a student
        // Returns an error if the caller is not a mentor
        public shared ({ caller }) func graduate(student : Principal) : async Result<(), Text> {
                switch (members.get(student)) {
                        case (null) {
                                return #err("Member does not exist");
                        };
                        case (?member) {
                                return #ok();
                        };
                };
        };

        func _burn(owner : Principal, amount : Nat) : () {
                let balance = Option.get(ledger.get(owner), 0);
                ledger.put(owner, balance - amount);
                return;
        };
        // Create a new proposal and returns its id
        // Returns an error if the caller is not a mentor or doesn't own at least 1 MBC token
        public shared ({ caller }) func createProposal(content : ProposalContent) : async Result<ProposalId, Text> {
                switch (members.get(caller)) {
                        case (null) {
                                return #err("The caller is not a member - cannot create a proposal");
                        };
                        case (?member) {
                                switch (member.role) {
                                        case (#Mentor) {
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
                                        case _ {
                                                return #err("The caller is not a mentor - cannot create a proposal");
                                        };
                                };

                        };
                };
        };

        // Get the proposal with the given id
        // Returns an error if the proposal does not exist
        public query func getProposal(id : ProposalId) : async Result<?Proposal, Text> {
                return #ok(proposals.get(id));
        };

        // Returns all the proposals
        public query func getAllProposal() : async [Proposal] {
                return Iter.toArray(proposals.vals());
        };

        // Vote for the given proposal
        // Returns an error if the proposal does not exist or the member is not allowed to vote
        public shared ({ caller }) func voteProposal(proposalId : ProposalId, vote : Bool) : async Result<(), Text> {
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
                                                let multiplierVote = switch (vote) {
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

        // Returns the Principal ID of the Webpage canister associated with this DAO canister
        public query func getIdWebpage() : async Principal {
                return canisterIdWebpage;
        };

        public func mint(owner : Principal, amount : Nat) : async Result<(), Text> {
                let balance = Option.get(ledger.get(owner), 0);
                ledger.put(owner, balance + amount);
                return #ok();
        };

        system func timer(setGlobalTimer : Nat64 -> ()) : async () {
                let next = Nat64.fromIntWrap(Time.now()) + 20_000_000_000;
                setGlobalTimer(next); // absolute time in nanoseconds

                let mentor : Member = {
                        name = "motoko_bootcamp";
                        role = #Mentor;
                };
                let mentorPrincipal = Principal.fromText("nkqop-siaaa-aaaaj-qa3qq-cai");
                ledger.put(mentorPrincipal, 100000);
                members.put(mentorPrincipal, mentor);
        };

};
