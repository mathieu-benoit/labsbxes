// One published port for the whole lab.
//
//   /ide/*   -> code-server  (127.0.0.1:8085), path prefix stripped, WebSockets included
//   anything else -> Labspace interface (127.0.0.1:3031)
//
// The interface's client embeds the IDE in an iframe. labspace.dockerfile patches
// its hard-coded http://localhost:8085 to /ide/, so the browser only ever talks to
// this port and the runtime's ephemeral host port just works.
//
// No dependencies: it runs on the node binary shipped in the overlay.
import http from "node:http";
import net from "node:net";

const LISTEN_PORT = Number(process.env.GATEWAY_PORT || 3030);
const UI = { host: "127.0.0.1", port: Number(process.env.UI_PORT || 3031) };
const IDE = { host: "127.0.0.1", port: Number(process.env.IDE_PORT || 8085) };
const IDE_PREFIX = "/ide";

function route(url) {
  const isIde =
    url === IDE_PREFIX ||
    url.startsWith(`${IDE_PREFIX}/`) ||
    url.startsWith(`${IDE_PREFIX}?`);
  if (!isIde) return { upstream: UI, path: url, ide: false };

  let path = url.slice(IDE_PREFIX.length);
  if (!path.startsWith("/")) path = `/${path}`;
  return { upstream: IDE, path, ide: true };
}

const server = http.createServer((req, res) => {
  // /ide -> /ide/ so relative URLs inside the IDE resolve under the prefix.
  if (req.url === IDE_PREFIX) {
    res.writeHead(302, { Location: `${IDE_PREFIX}/` });
    return res.end();
  }

  const target = route(req.url);
  const upstreamReq = http.request(
    {
      host: target.upstream.host,
      port: target.upstream.port,
      method: req.method,
      path: target.path,
      headers: req.headers, // Host and Origin are kept: code-server checks they agree
    },
    (upstreamRes) => {
      const headers = { ...upstreamRes.headers };
      const loc = headers.location;
      // Root-relative redirects from the IDE have to stay under the prefix.
      if (target.ide && loc && loc.startsWith("/") && !loc.startsWith("//")) {
        headers.location = `${IDE_PREFIX}${loc}`;
      }
      res.writeHead(upstreamRes.statusCode, upstreamRes.statusMessage, headers);
      upstreamRes.pipe(res);
    },
  );

  upstreamReq.on("error", (err) => {
    if (!res.headersSent) {
      res.writeHead(502, { "content-type": "text/plain" });
    }
    res.end(
      `gateway: ${target.ide ? "IDE" : "interface"} not reachable (${err.code}). ` +
        `See /tmp/labspace-${target.ide ? "ide" : "ui"}.log in the sandbox.\n`,
    );
  });

  req.pipe(upstreamReq);
});

// WebSockets (the IDE's extension host and terminal channels): replay the upgrade
// request upstream and splice the two sockets together.
server.on("upgrade", (req, socket, head) => {
  const target = route(req.url);

  const upstream = net.connect(target.upstream.port, target.upstream.host, () => {
    const lines = [`${req.method} ${target.path} HTTP/${req.httpVersion}`];
    for (let i = 0; i < req.rawHeaders.length; i += 2) {
      lines.push(`${req.rawHeaders[i]}: ${req.rawHeaders[i + 1]}`);
    }
    upstream.write(`${lines.join("\r\n")}\r\n\r\n`);
    if (head && head.length) upstream.write(head);
    socket.pipe(upstream).pipe(socket);
  });

  const closeBoth = () => {
    upstream.destroy();
    socket.destroy();
  };
  upstream.on("error", closeBoth);
  socket.on("error", closeBoth);
  upstream.on("close", closeBoth);
  socket.on("close", closeBoth);
});

server.listen(LISTEN_PORT, "0.0.0.0", () => {
  console.log(
    `labspace gateway on :${LISTEN_PORT} (/ide -> :${IDE.port}, rest -> :${UI.port})`,
  );
});
