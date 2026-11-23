// Landing page (a blade per kit) and a rendering of each kit's README.md.
// Routes: #/ (catalog) and #/kits/<id> (one kit). kits.json lists the kits;
// config.json, written by build.sh, names the release the site was built from.
(function () {
  "use strict";

  var app = document.getElementById("app");
  var DEFAULTS = { repo: "mathieu-benoit/labsbxes", ref: "main", version: "" };
  var state = { kits: null, config: DEFAULTS, readmes: {} };

  function el(tag, attrs, children) {
    var node = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "text") node.textContent = attrs[k];
      else node.setAttribute(k, attrs[k]);
    });
    (children || []).forEach(function (c) { if (c) node.appendChild(c); });
    return node;
  }

  function icon(name, cls) {
    return el("span", { "class": "material-symbols-outlined" + (cls ? " " + cls : ""), "aria-hidden": "true", text: name });
  }

  function chip(text, primary, iconName) {
    return el("span", { "class": "catalog-chip" + (primary ? " catalog-chip-primary" : "") },
      [iconName ? icon(iconName) : null, document.createTextNode(text)]);
  }

  function getJSON(url, fallback) {
    return fetch(url, { cache: "no-cache" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
      .catch(function () { return fallback; });
  }

  function repoUrl(kind, path) {
    return "https://github.com/" + state.config.repo + "/" + kind + "/" + state.config.ref + (path ? "/" + path : "");
  }

  // --- Catalog -------------------------------------------------------------

  function renderCatalog() {
    document.title = "Labspace on Docker Sandboxes";
    var v = state.config.version;
    var header = el("header", { "class": "catalog-header" }, [
      el("div", { "class": "catalog-brand" }, [
        el("span", { "class": "catalog-brand-logo" }, [icon("science")]),
        el("span", { "class": "catalog-eyebrow", text: "Labspace on Docker Sandboxes" })
      ]),
      el("h1", { "class": "catalog-title", text: "Start here" }),
      el("p", { "class": "catalog-subtitle", text:
        "Hands-on labs that run in a Docker Sandbox: instructions on the left, VS Code on the right, " +
        "and a private Docker engine. Pick a kit to see how to run it." })
    ]);

    var grid = el("ul", { "class": "catalog-grid" });
    state.kits.forEach(function (kit) {
      var meta = el("span", { "class": "catalog-card-meta" });
      if (v && kit.package) meta.appendChild(chip(v, true, "sell"));
      kit.chips.forEach(function (c) { meta.appendChild(chip(c)); });
      // An entry with "url" is a lab published elsewhere: the card opens it in
      // a new tab instead of routing inside this site.
      var link = kit.url
        ? { "class": "catalog-card", href: kit.url, target: "_blank", rel: "noopener" }
        : { "class": "catalog-card", href: kit.page ? "#/" + kit.id : "#/kits/" + kit.id };
      grid.appendChild(el("li", {}, [
        el("a", link, [
          el("span", { "class": "catalog-card-icon" }, [icon(kit.icon)]),
          el("span", { "class": "catalog-card-body" }, [
            el("span", { "class": "catalog-card-title", text: kit.title }),
            el("span", { "class": "catalog-card-desc", text: kit.description }),
            meta
          ]),
          icon(kit.url ? "open_in_new" : "arrow_forward", "catalog-card-arrow")
        ])
      ]));
    });

    var footer = el("footer", { "class": "catalog-footer" }, [
      document.createTextNode((v ? "Release " + v + " · " : "") + "Source on "),
      el("a", { href: repoUrl("tree", ""), text: "GitHub" })
    ]);

    app.replaceChildren(header, grid, footer);
  }

  // --- Kit page ------------------------------------------------------------

  function slug(text) {
    return text.toLowerCase().trim().replace(/[^\w\- ]+/g, "").replace(/\s/g, "-");
  }

  function normalize(path) {
    var out = [];
    path.split("/").forEach(function (part) {
      if (part === "" || part === ".") return;
      if (part === "..") out.pop(); else out.push(part);
    });
    return out.join("/");
  }

  // Relative links in a README point into the repository. Links to another
  // kit's folder or README stay on the site; the rest open on GitHub.
  function rewriteLinks(root, kit) {
    root.querySelectorAll("a[href]").forEach(function (a) {
      var href = a.getAttribute("href");
      if (href.charAt(0) === "#") {
        var id = decodeURIComponent(href.slice(1));
        a.addEventListener("click", function (e) {
          var target = document.getElementById(id);
          if (target) { e.preventDefault(); target.scrollIntoView({ behavior: "smooth" }); }
        });
        return;
      }
      if (/^[a-z][a-z0-9+.-]*:/i.test(href)) {
        a.target = "_blank";
        a.rel = "noopener";
        return;
      }
      var parts = href.split("#");
      var path = normalize(kit.dir + "/" + parts[0]);
      var match = state.kits.filter(function (k) {
        return k.dir && (path === k.dir || path === k.dir + "/README.md");
      })[0];
      if (match) {
        a.setAttribute("href", "#/kits/" + match.id);
        return;
      }
      // GitHub redirects /blob/ to /tree/ for folders.
      a.setAttribute("href", repoUrl("blob", path) + (parts[1] ? "#" + parts[1] : ""));
      a.target = "_blank";
      a.rel = "noopener";
    });
  }

  function decorate(root, kit) {
    root.querySelectorAll("h1, h2, h3, h4").forEach(function (h) {
      if (!h.id) h.id = slug(h.textContent);
    });
    root.querySelectorAll("table").forEach(function (t) {
      var wrap = el("div", { "class": "table-wrap" });
      t.parentNode.insertBefore(wrap, t);
      wrap.appendChild(t);
    });
    root.querySelectorAll("pre").forEach(function (pre) {
      var wrap = el("div", { "class": "code-block" });
      pre.parentNode.insertBefore(wrap, pre);
      wrap.appendChild(pre);
      var btn = el("button", { "class": "copy", type: "button", title: "Copy", "aria-label": "Copy to clipboard" }, [icon("content_copy")]);
      btn.addEventListener("click", function () {
        var text = pre.textContent.replace(/\n$/, "");
        var done = function () {
          btn.firstChild.textContent = "check";
          setTimeout(function () { btn.firstChild.textContent = "content_copy"; }, 1500);
        };
        if (navigator.clipboard) navigator.clipboard.writeText(text).then(done, function () {});
      });
      wrap.appendChild(btn);
    });
    rewriteLinks(root, kit);
  }

  function renderKit(kit) {
    document.title = kit.title + " · Labspace on Docker Sandboxes";
    var back = el("a", { "class": "kit-back", href: "#/" }, [icon("arrow_back"), document.createTextNode("All kits")]);

    var pullRef = kit.package + (state.config.version ? ":" + state.config.version : "");
    var copyRef = el("button", { "class": "copy", type: "button", title: "Copy", "aria-label": "Copy the package reference",
      style: "position:static;border-color:var(--border);background:var(--bg);color:var(--muted)" }, [icon("content_copy")]);
    copyRef.addEventListener("click", function () {
      if (navigator.clipboard) navigator.clipboard.writeText(pullRef).then(function () {
        copyRef.firstChild.textContent = "check";
        setTimeout(function () { copyRef.firstChild.textContent = "content_copy"; }, 1500);
      }, function () {});
    });

    var meta = el("div", { "class": "catalog-card-meta" });
    if (state.config.version) meta.appendChild(chip(state.config.version, true, "sell"));
    kit.chips.forEach(function (c) { meta.appendChild(chip(c)); });

    var header = el("header", { "class": "kit-header" }, [
      el("span", { "class": "catalog-card-icon" }, [icon(kit.icon)]),
      el("div", { "class": "kit-header-body" }, [
        el("h1", { text: kit.title }),
        el("p", { "class": "catalog-subtitle", text: kit.description }),
        meta,
        el("div", { "class": "kit-actions" }, [
          el("div", { "class": "pull" }, [el("code", { text: pullRef }), copyRef]),
          el("a", { "class": "btn", href: repoUrl("tree", kit.dir), target: "_blank", rel: "noopener" },
            [icon("code"), document.createTextNode("Source")]),
          el("a", { "class": "btn", href: "https://github.com/" + state.config.repo.split("/")[0] + "/" +
            state.config.repo.split("/")[1] + "/pkgs/container/" + encodeURIComponent(kit.package.split("/").slice(2).join("/")),
            target: "_blank", rel: "noopener" }, [icon("inventory_2"), document.createTextNode("Package")])
        ])
      ])
    ]);

    var body = el("article", { "class": "markdown" }, [el("p", { "class": "loading", text: "Loading README…" })]);
    app.replaceChildren(back, header, body);
    window.scrollTo(0, 0);

    var cached = state.readmes[kit.id];
    var load = cached ? Promise.resolve(cached) : fetch("kits/" + kit.id + "/README.md", { cache: "no-cache" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.text(); });
    load.then(function (md) {
      state.readmes[kit.id] = md;
      if (location.hash !== "#/kits/" + kit.id) return;
      body.innerHTML = DOMPurify.sanitize(marked.parse(md, { gfm: true }));
      decorate(body, kit);
    }).catch(function () {
      body.replaceChildren(el("p", { "class": "error" }, [
        document.createTextNode("Couldn't load this README. Read it on "),
        el("a", { href: repoUrl("blob", kit.dir + "/README.md"), text: "GitHub" }),
        document.createTextNode(".")
      ]));
    });
  }

  // --- Static page (an entry with "page" instead of "dir") -----------------

  function renderPage(entry) {
    document.title = entry.title + " · Labspace on Docker Sandboxes";
    var back = el("a", { "class": "kit-back", href: "#/" }, [icon("arrow_back"), document.createTextNode("All kits")]);
    var meta = el("div", { "class": "catalog-card-meta" });
    entry.chips.forEach(function (c) { meta.appendChild(chip(c)); });
    var header = el("header", { "class": "kit-header" }, [
      el("span", { "class": "catalog-card-icon" }, [icon(entry.icon)]),
      el("div", { "class": "kit-header-body" }, [
        el("h1", { text: entry.title }),
        el("p", { "class": "catalog-subtitle", text: entry.description }),
        meta
      ])
    ]);
    var body = el("article", { "class": "markdown page" }, [el("p", { "class": "loading", text: "Loading…" })]);
    app.replaceChildren(back, header, body);
    window.scrollTo(0, 0);

    var cached = state.readmes[entry.id];
    var load = cached ? Promise.resolve(cached) : fetch(entry.page, { cache: "no-cache" })
      .then(function (r) { if (!r.ok) throw new Error(r.status); return r.text(); });
    load.then(function (html) {
      state.readmes[entry.id] = html;
      if (location.hash !== "#/" + entry.id) return;
      body.innerHTML = DOMPurify.sanitize(html, { ADD_ATTR: ["target"] });
      // Links into the repository follow the release the site was built from.
      body.querySelectorAll("a[data-repo-path]").forEach(function (a) {
        a.setAttribute("href", repoUrl("blob", a.getAttribute("data-repo-path")));
      });
      body.querySelectorAll("a[target=_blank]").forEach(function (a) { a.rel = "noopener"; });
    }).catch(function () {
      body.replaceChildren(el("p", { "class": "error", text: "Couldn't load this page." }));
    });
  }

  // --- Router --------------------------------------------------------------

  function route() {
    var m = location.hash.match(/^#\/kits\/([\w-]+)/);
    var kit = m && state.kits.filter(function (k) { return k.dir && k.id === m[1]; })[0];
    if (kit) { renderKit(kit); return; }
    var p = location.hash.match(/^#\/([\w-]+)$/);
    var page = p && state.kits.filter(function (k) { return k.page && k.id === p[1]; })[0];
    if (page) renderPage(page); else renderCatalog();
  }

  Promise.all([getJSON("kits.json", null), getJSON("config.json", DEFAULTS)]).then(function (res) {
    if (!res[0]) {
      app.replaceChildren(el("p", { "class": "error", text: "Couldn't load the list of kits." }));
      return;
    }
    state.kits = res[0];
    state.config = Object.assign({}, DEFAULTS, res[1]);
    window.addEventListener("hashchange", route);
    route();
  });
})();
