package auth

import (
	"context"
	"strings"
	"encoding/json"
	"golang.org/x/oauth2"
	"log"
	"net/http"
)

func Office365(addUser func(user, token string), clientID, clientSecret, domain string) (login, callback http.HandlerFunc) {
	ctx := context.Background()
	conf := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		Scopes:       []string{"user.read"},
		Endpoint: oauth2.Endpoint{
			AuthURL:  "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
			TokenURL: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
		},
	}

	login = func(w http.ResponseWriter, r *http.Request) {
		url := conf.AuthCodeURL("state", oauth2.AccessTypeOnline)

		http.Redirect(w, r, url, http.StatusFound)
	}

	callback = func(w http.ResponseWriter, r *http.Request) {
		code := r.FormValue("code")

		tok, err := conf.Exchange(ctx, code)
		if err != nil {
			log.Println(err)
			return
		}

		client := conf.Client(ctx, tok)

		user, err := getOfficeUser(client)
		if err != nil {
			log.Println(err)
			return
		}

		if isInDomain(user, domain) {
			token := strId()
			addUser(user, token)

			http.Redirect(w, r, "/?user="+user+"&token="+token, http.StatusFound)
		} else {
			http.Redirect(w, r, "/?error=not_in_org", http.StatusFound)
		}
	}

	return login, callback
}

func getOfficeUser(client *http.Client) (string, error) {
	resp, err := client.Get("https://graph.microsoft.com/v1.0/me/")
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var data struct {
		Mail string `json:"mail"`
	}
	if err = json.NewDecoder(resp.Body).Decode(&data); err != nil {
		return "", err
	}

	return data.Mail, nil
}

func isInDomain(mail, domain string) bool {
	return strings.HasSuffix(mail, domain)
}
