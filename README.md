[Purpose](#purpose)
[Caveat emptor](#caveat-emptor)
[Contributing](#contributing)
[Credits](#credits)
[HOPETODOs](#hopetodos)

# Purpose

Maybe this will become my ever-growing, ever-improving, Swiss Army
Toolkit of functions-as-cmd-line-tools and useful-to-me patterns.

It is unlikely to be useful as-is to you. However, you might find
some of the ideas or techniques interesting (almost none of them
are original).

In any case, this stuff has emerged from my personal motivations to:

- reinvent the wheel for fun and profit
- avoid rewriting all of these all over the place, as I end up
  doing ever so often
- get better at text processing. That stuff is everywhere!
- benefit from stable, fast tools, with well-known warts, and
  Because The Masters Already Solved It Better Decades Ago
- improve personal/team productivity
- preserve tool-building autonomy
- learn about good and successful design
- learn about bad _and_ successful design
- go down the winding rabbit pipes of computer history.

See also [oxo](https://github.com/adityaathalye/oxo), a game of Noughts and Crosses, written in Bash.

# Usage

I happen to use these tools on Ubuntu 18+ LTS, with Bash 4.4+. Maybe
they will also work just fine on other Debian-like distros, with Bash 4+.

Each "utility" file would have its own usage guide.

# Caveat emptor

These utilities are NOT designed to be portable across shells or older
Bash versions or operating systems. Nor should they be presumed secure.
If I haven't tried, they certainly aren't. And even if I did, they very
well may not be.

I'm still learning from my mistakes, after all. Ergo, by perusing these,
you accept all the horrible ramifications of your life choice.

# Contributing

I'll be happy to discuss bugs, design ideas etc. via email or github's
issues feature. Suppose a discussion leads to a thing I'd like to add
to this repo, I'll work with you to bring it in with due credit.

However, I do not intend this for use by others, and will not heed
unsolicited pull requests.

# Credits

Too many to name, but some important ones are:

- Several friends and colleagues (especially those who failed to
  caution me about the perils of Shell scripting)
- Classic Shell Scripting (Robbins and Beebee)
- bash manpage authors, tool manpage authors, especially the ones
  who document EXAMPLES
- mtxia.com, jpnc.info, catb.org, wiki.bash-hackers.org, tldp.org
- Various StackOverflows, githubs, subreddits, HackerNewses,
  ${RANDOM_BLOGGERS}... erm... "The Internets"?

# HOPETODOs

- Read "The Unix Programming Environment".
- Peruse [google's shell style guide](https://google.github.io/styleguide/shell.xml). They seem to know a bit or two.
- Understand plan9. Migrate to plan9. Upgrade to plan10.
  Wait, no that's not macOS.
- Many, many other things.

# Copyright and License

Copyright © 2018-2019 [Aditya Athalye](https://adityaathalye.com).

Distributed under the [MIT license](https://github.com/inclojure-org/clojure-by-example/blob/master/LICENSE).
