> This web app is online at [thkitchensappliances.com](https://thkitchensappliances.com/)

Since rust is usually used for **systems programming** and **cli tools**, you might be wondering why we chose to chose to write an entire web app including the frontend with rust when there are probably close to _400 million_ different JavaScript frameworks for that exact purpose.

Well, the short answer is the [Leptos](https://www.leptos.dev/) framework.

![[Leptos Image.png]]

### Leptos: Introduction
**Leptos** is a full stack web framework written entirely in rust, and while syntactically similar to frameworks like [React](https://react.dev/) or [Solid](https://www.solidjs.com/) some highlight features include:
- **[Isomorphic Server Functions](https://book.leptos.dev/server/25_server_functions.html):** Syntax sugar for api endpoints which allow them to be called as regular async functions, allowing code co-location by feature.
- [RSX](https://book.leptos.dev/view/01_basic_component.html): Which provides a HTML like markup language for your components in the form of the `view!` macro:
```rust
#[component]
fn App() -> impl IntoView {
    let (count, set_count) = signal(0);

    view! {
        <button
            on:click=move |_| set_count.set(3)
        >
            "Click me: "
            {count}
        </button>
        <p>
            "Double count: "
            {move || count.get() * 2}
        </p>
    }
}
```
- **Explicit Error Handling:** Since Leptos is written in Rust, it shares the almost authoritarian approach to typing as the rest of Rust, producing safe, fast code.

### Developer Experience: The good
Overall, developing with Leptos was a particularly enjoyable experience for me, in part due to the excellent integration with [rust-analyzer](https://rust-analyzer.github.io/), the official Rust language server. I found refactoring code to be a joy, particularly with [Neovim](https://neovim.io/)'s [Telescope](https://github.com/nvim-telescope/telescope.nvim) diagnostics viewer, which allows jumping to the point where errors occur:

![[Telescope Image.png]]

In general, we found that because of **Rust's type system**, we were able to **avoid many common errors** in development by it forcing us to handle all the cases, even in the user interface. For example, take this simplified example:
```rust
let featured = Resource::new(move || (), move |_| get_featured_products());

view! {
	<Transition fallback=move || {
		view! { <p>"Loading featured products..."</p> }
	}>
		{move || Suspend::new(async move {
			either!(
				featured.await,
				Ok(featured) => view! {
					<FeaturedProductsList featured/>
				},
				Err(error) => {
					warn!("Error occurred fetching featured products: {error}");

					view! { <p>"Error loading featured products."</p>}
				},
			)
		})}
	</Transition>
}
```

This is used to **fetch and render** a list of featured `Product`s, but also handles all of the cases where something other than the correct path has happened:
- The `Transition` component provides an **elegant way** to mask loading screens by using a cached local version of what the component looked like previously, avoiding re-renders until the server responds.
- The `either!` macro functions almost identically to the `match` statement in vanilla Rust code, allowing two diverging expressions to be rendered in the UI by matching a pattern. Here, the `Ok` and `Err` values are both handled, therefore it will compile correctly.

This code is no less readable than the equivalent **React** or **Solid** code, but simultaneously is an [order of magnitude faster](https://www.youtube.com/live/jV19k2BhAe8) in production because of the nature of Rust and Web Assembly.

### Developer Experience: The bad
Unfortunately, Leptos is not perfect on all fronts and we did end up having a number of gripes with it.

**Slow Compile Times**: While this issue plagues the Rust ecosystem in general it is particularly noticable here because of the massive chasm between tools like [vite](https://vite.dev/) and [cargo leptos](https://github.com/leptos-rs/cargo-leptos). Often we found that small changes such as changing text in a paragraph or [tailwind classes](https://tailwindcss.com/) would lead to upwards of a **2 minute** recompile, which is utterly awful compared to standard web technologies which can do it in a matter of milliseconds. This is, obviously, terrible for iteration and likely the most frustrating outstanding issue.

**Small Community**: Since Leptos is relatively new, not many products have cropped up using or supporting Leptos, hence sources like **Stack Overflow** or **Generative AI** are lacking in quality examples, which some members of my team were particularly irked by. In addition, while the official documentation is usually high quality, there are often missing sections for commonly used features, such as [either](https://docs.rs/leptos/latest/leptos/either/index.html), which as of writing has documentation which looks like:

![[Either Documentation.png]]

**Uncommon (but still frequent enough) Obtuse Errors**: Because of the framework's heavy reliance on macros and traits to achieve it's features, the errors produces are often lengthy and difficult to reason about. In addition to this, due to web assembly not being a super mature platform, you will have runtime issues that look like [this one](https://github.com/briansmith/ring/issues/1372), for which the eventual solution was to compile with [Clang](https://clang.llvm.org/) over [GCC](https://gcc.gnu.org/), despite being both technically compliant with the standard.

### Environment and Deployment
While not strictly a part of the framework, while on the topic of this project I would love to take the opportunity to mention [devenv](https://devenv.sh/) and [deploy-rs](https://github.com/serokell/deploy-rs), two [Nix](https://nixos.org/) based tools which made deploying our release build a breeze.

#### Devenv
The _devenv_ tool provided us with a consistent, reproducible developer environment for the duration of our project. It allowed us to bundle system packages in a clean manner, which benefited us by allowing us to setup compiler improvements such as [the mold linker](https://github.com/rui314/mold) or [cranelift](https://cranelift.dev/) which massively sped up compile times.

Compared to options like [Docker](https://www.docker.com/), devenv has a far lower overhead as it runs in a [nix shell](https://nixos.wiki/wiki/Development_environment_with_nix-shell) instead of a [container](https://opencontainers.org/), while still being able to be ran on any of our team's machines.

Here is the **process compose** UI, which manages launching long running stuff like a development server and database on two processes.

![[Devenv Image.png]]

#### Deploy-rs
[Deploy-rs](https://github.com/serokell/deploy-rs) is another great nix based tool we made heavy use of when developing with Leptos. It allows you to take any nix system and build and deploy a declarative system configuration (i.e. with your server running as a [systemd](https://en.wikipedia.org/wiki/Systemd) service). A section of this configuration might look like:
```rust
  services.postgresql = {
    enable = true;
    ensureDatabases = ["thkitchenappliances"];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser                auth-method
      local all       all                   trust
      host  all       all     ::1/128       trust
      host  all       all     127.0.0.1/32  trust
    '';
  };

  systemd.services.${name} = {
    enable = true;
    description = "TH Kitchen Appliances Server";
    serviceConfig = {
      ExecStart = "${derivation}/bin/${name}";
      WorkingDirectory = "${derivation}/bin";
      Restart = "on-failure";
    };
    wantedBy = ["default.target"];
  };
```

As you can see, this instructs the nix system to start both **postgres** and **our app** on boot, and to restart our server automatically if it crashes for some reason. This deploys to one system to run both our server and the database because the client has a **small amount of traffic**, but configuring a **cluster** is just as easy as a single machine.

Deploy-rs allowed us to easily make 0 downtime reliable deploys to our server, keeping our client and their customers happy, while allowing us to not be afraid to make mistakes.

### Conclusion
In conclusion, I would absolutely recommend Leptos for use in production as it has produced us a reliable web app which performs far better than the vast majority of web apps while making maintenence a breeze.