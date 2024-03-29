defmodule Thurim.PushRules do
  alias Thurim.User

  def default_push_rules(localpart) do
    %{
      global: %{
        content: [
          %{
            actions: [
              "notify",
              %{
                set_tweak: "sound",
                value: "default"
              },
              %{
                set_tweak: "highlight"
              }
            ],
            default: true,
            enabled: true,
            pattern: localpart,
            rule_id: ".m.rule.contains_user_name"
          }
        ],
        override: [
          %{
            actions: [
              "dont_notify"
            ],
            conditions: [],
            default: true,
            enabled: false,
            rule_id: ".m.rule.master"
          },
          %{
            actions: [
              "dont_notify"
            ],
            conditions: [
              %{
                key: "content.msgtype",
                kind: "event_match",
                pattern: "m.notice"
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.suppress_notices"
          }
        ],
        room: [],
        sender: [],
        underride: [
          %{
            actions: [
              "notify",
              %{
                set_tweak: "sound",
                value: "ring"
              },
              %{
                set_tweak: "highlight",
                value: false
              }
            ],
            conditions: [
              %{
                key: "type",
                kind: "event_match",
                pattern: "m.call.invite"
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.call"
          },
          %{
            actions: [
              "notify",
              %{
                set_tweak: "sound",
                value: "default"
              },
              %{
                set_tweak: "highlight"
              }
            ],
            conditions: [
              %{
                kind: "contains_display_name"
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.contains_display_name"
          },
          %{
            actions: [
              "notify",
              %{
                set_tweak: "sound",
                value: "default"
              },
              %{
                set_tweak: "highlight",
                value: false
              }
            ],
            conditions: [
              %{
                kind: "room_member_count",
                is: "2"
              },
              %{
                kind: "event_match",
                key: "type",
                pattern: "m.room.message"
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.room_one_to_one"
          },
          %{
            actions: [
              "notify",
              %{
                set_tweak: "sound",
                value: "default"
              },
              %{
                set_tweak: "highlight",
                value: false
              }
            ],
            conditions: [
              %{
                key: "type",
                kind: "event_match",
                pattern: "m.room.member"
              },
              %{
                key: "content.membership",
                kind: "event_match",
                pattern: "invite"
              },
              %{
                key: "state_key",
                kind: "event_match",
                pattern: User.mx_user_id(localpart)
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.invite_for_me"
          },
          %{
            actions: [
              "notify",
              %{
                set_tweak: "highlight",
                value: false
              }
            ],
            conditions: [
              %{
                key: "type",
                kind: "event_match",
                pattern: "m.room.member"
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.member_event"
          },
          %{
            actions: [
              "notify",
              %{
                set_tweak: "highlight",
                value: false
              }
            ],
            conditions: [
              %{
                key: "type",
                kind: "event_match",
                pattern: "m.room.message"
              }
            ],
            default: true,
            enabled: true,
            rule_id: ".m.rule.message"
          }
        ]
      }
    }
  end
end
