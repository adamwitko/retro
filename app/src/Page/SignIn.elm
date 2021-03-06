module Page.SignIn exposing (view)

import Bulma
import Html exposing (Html)
import Html.Attributes as Attr
import Views.Footer


view : Html msg
view =
    Html.div [ Attr.class "site-content" ]
        [ Html.section [ Attr.class "hero is-dark is-bold is-large fill-height" ]
            [ Html.div [ Attr.class "hero-body" ]
                [ Bulma.container
                    [ Bulma.title "Retro"
                    , Bulma.subtitle "For running retrospectives remotely"
                    , Html.div [ Attr.class "field is-grouped" ]
                        [ Html.p [ Attr.class "control" ]
                            [ Html.a
                                [ Attr.class "button is-primary is-outlined"
                                , Attr.href "/oauth/github/login"
                                ]
                                [ Html.text "Sign-in with GitHub" ]
                            ]
                        , Html.p [ Attr.class "control" ]
                            [ Html.a
                                [ Attr.class "button is-danger is-outlined"
                                , Attr.href "/oauth/office365/login"
                                ]
                                [ Html.text "Sign-in with Office365" ]
                            ]
                        ]
                    ]
                ]
            ]
        , Views.Footer.view
        ]
