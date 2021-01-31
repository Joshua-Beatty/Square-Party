var serverIP = "localhost"
process.on('message', function(m) {
    if (m.starting == true) {
        console.log("starting server channle" + m.channel);

        const noobhub = require('./client');
        const hub = noobhub.new({
            server: serverIP,
            port: 1337
        });

        hub.subscribe({
            channel: m.channel,
            callback: (data) => {
            	/*
                hub.publish({
                    user: "host",
                    data: `${Math.random()}`
                });
                */
            },
            subscribedCallback: (socket) => {
                //console.log('subscribedCallback (got socket)');
                /*
                                let i = 0;
                                setInterval(() => {
                                    hub.publish({
                                        from: myName,
                                        data: `${i++} ${Math.random()}`
                                    });
                                }, dt);*/
            },
            errorCallback: (err) => {
                //console.log('error callback', err);
                process.exit(1);
            }
        });
    }
});