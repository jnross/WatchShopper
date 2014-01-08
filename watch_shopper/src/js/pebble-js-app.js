Pebble.addEventListener("ready",
    function(e) {
        console.log("Hello world! - Sent from your javascript application.");
        sendChecklist(fake_checklist);
        
        Pebble.addEventListener("appmessage",
		  function(e) {
		    console.log("Received message: " + JSON.stringify(e.payload));
		  }
		);

		Pebble.addEventListener("showConfiguration",
			function(e) {
				Pebble.openURL("http://jnross.github.io/watch_shopper_configuration.html");
			}
		);

		Pebble.addEventListener("webviewclosed",
		  function(e) {
		    var configuration = JSON.parse(decodeURIComponent(e.response));
		    console.log("Configuration window returned: ", JSON.stringify(configuration));
		  }
		);
    }
);

var fake_checklist = {};
fake_checklist.name = "A Fake Checklist";
fake_checklist.list_id = 0;
var fake_item = {};
fake_item.name = "A Fake Item";
fake_item.flags = 0;
fake_item.item_id = 0;
fake_checklist.items = [fake_item];

function sendChecklist(checklist) {
	var data = buildDataForChecklist(checklist);
	console.log("data to send: " + data);
  	var transactionId = Pebble.sendAppMessage( { "CMD_LIST_ITEMS_START": data },
		function(e) {
		console.log("Successfully delivered message with transactionId="
		  + e.data.transactionId);
		},
		function(e) {
		console.log("Unable to deliver message with transactionId="
		  + e.data.transactionId
		  + " Error is: " + e.error.message);
		}
  	);
}

function buildDataForChecklist(checklist) {
	var data = [];
	data.push(checklist.list_id);
	data.push(checklist.name, 0);
	data.push(checklist.items.length);
	for (var i = 0; i < checklist.items.length; i++) {

		var item = checklist.items[i];
		var itemData = buildDataForChecklistItem(item);
		data = data.concat(itemData);
	}
	return data;
}

function buildDataForChecklistItem(item) {
	var data = [];
	data.push(item.item_id);
	data.push(item.name, 0);
	data.push(item.flags);
	return data;
}
