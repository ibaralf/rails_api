module SlircleHelper

  def get_instance_message
    instance_json = {
      "text": "Did you want to run a test?",
      "attachments": [ {  
        "text": "Choose environment to execute test.",
        "fallback": "You need to specify test instance.",
        "callback_id": "selected_instance",
        "color": "#3AA3E3",
        "attachment_type": "default",
        "actions": [ 
          { "name": "instance",
          "text": "Production",
          "type": "button",
          "value": "prod" },
          { "name": "instance",
          "text": "Release",
          "type": "button",
          "value": "release" },
          { "name": "instance",
          "text": "cancel",
          "style": "danger",
          "type": "button",
          "value": "cancel" },

          { "name": "instance",
            "text": "Select environment",
            "type": "select",
            "options": [
              { "text": "Burgundy",
                "value": "burgundy" },
              { "text": "EC2",
                "value": "ec2" },
              { "text": "Selfoss",
              "value": "selfoss" },
              { "text": "Stage3",
                "value": "stage3" },
              { "text": "Thredtest",
                "value": "thredtest" },
              { "text": "Wrangler",
                "value": "wrangler" },
              { "text": "Zoolander",
                "value": "zoolander" }
            ] }
       ]
    } ] }
  return instance_json
  end

  



end
