import Types "types";
import Result "mo:base/Result";
import Text "mo:base/Text";
actor Webpage {

    type Result<A, B> = Result.Result<A, B>;
    type HttpRequest = Types.HttpRequest;
    type HttpResponse = Types.HttpResponse;

    // The manifesto stored in the webpage canister should always be the same as the one stored in the DAO canister
    stable var manifesto : Text = "Let's graduate!";

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

        webpage := webpage # "<div><h1>  Name</h1></div>";
        webpage := webpage # "<em>manifesto</em>";
        webpage := webpage # "<div logo</div>";
        webpage := webpage # "<div><?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' id='Layer_1' data-name='Layer 1' width='512' height='512' viewBox='0 0 24 24'><path d='M15.5,6c-1.378,0-2.5,1.122-2.5,2.5s1.122,2.5,2.5,2.5,2.5-1.122,2.5-2.5-1.122-2.5-2.5-2.5Zm0,4c-.827,0-1.5-.673-1.5-1.5s.673-1.5,1.5-1.5,1.5,.673,1.5,1.5-.673,1.5-1.5,1.5ZM24,2.5c0-1.378-1.122-2.5-2.514-2.5-4.942,.141-9.444,2.552-13.111,7.001-1.586,.019-3.168,.404-4.585,1.115-2.302,1.155-3.79,3.661-3.79,6.384v.5H5c1.068,0,2.073,.416,2.829,1.171,.755,.756,1.171,1.76,1.171,2.829v5h.5c2.723,0,5.229-1.487,6.384-3.789,.712-1.417,1.096-3,1.115-4.586,4.448-3.667,6.86-8.17,7.001-13.125ZM4.238,9.01c1.034-.519,2.165-.845,3.317-.961-.098,.132-.196,.265-.293,.4-1.553,2.167-2.712,4.684-3.092,5.551H1.019c.166-2.15,1.393-4.074,3.219-4.99Zm10.752,10.752c-.917,1.826-2.84,3.053-4.99,3.219v-3.151c.868-.38,3.384-1.539,5.552-3.092,.135-.097,.268-.194,.4-.292-.116,1.152-.442,2.283-.961,3.317Zm-.021-3.837c-1.803,1.292-3.914,2.325-4.976,2.811-.064-1.236-.576-2.389-1.457-3.271-.882-.882-2.035-1.393-3.271-1.457,.486-1.062,1.519-3.173,2.811-4.976C10.629,5.469,15.033,1.184,21.5,1c.827,0,1.5,.673,1.5,1.486-.184,6.481-4.469,10.885-8.031,13.439ZM1.732,18.732c-.85,.849-1.419,3.881-1.524,4.48l-.124,.703,.703-.124c.599-.105,3.631-.674,4.48-1.524,.472-.472,.732-1.1,.732-1.768s-.26-1.296-.732-1.768c-.943-.944-2.592-.944-3.535,0Zm2.828,2.828c-.386,.386-1.934,.831-3.227,1.106,.275-1.293,.72-2.841,1.106-3.227,.283-.283,.66-.439,1.061-.439s.777,.156,1.061,.439,.439,.66,.439,1.061-.156,.777-.439,1.061Z'/></svg></div>";
        webpage := webpage # "<hr>";
        webpage := webpage # "<h2>Our goals:</h2>";
        webpage := webpage # "<ul>";
        webpage := webpage # "</ul>";
        return webpage;
    };

    // The webpage displays the manifesto
    public query func http_request(request : HttpRequest) : async HttpResponse {
        return ({
            status_code = 200;
            headers = [("Content-Type", "text/html; charset=UTF-8")];
            body = Text.encodeUtf8(_getWebpage());
            streaming_strategy = null;
        });
    };

    // This function should only be callable by the DAO canister (no one else should be able to change the manifesto)
    public shared ({ caller }) func setManifesto(newManifesto : Text) : async Result<(), Text> {
        manifesto := newManifesto;
        return #ok();
    };
};
