package tun2socks

import (
	"strconv"
	"github.com/xjasonlyu/tun2socks/v2/engine"
)

func Start(fd int, proxy string, mtu int) {
	key := &engine.Key{
		MTU:    mtu,
		Device: "fd://" + strconv.Itoa(fd),
		Proxy:  proxy,
	}
	engine.Insert(key)
	engine.Start()
}

func Stop() {
	engine.Stop()
}
