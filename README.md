# Acrostic PI

This is the source code for [the digital art installation "Acrostic Pi"](https://jmac.org/acrostic_pi/), which runs at [the Twitter account @AcrosticPi](https://twitter.com/acrosticpi).

## What is it?

Acrostic Pi builds a decimal representatin of π entirely from retweets discovered by happenstance. (It tries to limit itself to retweeting only "SFW" tweets.)

If it's configured properly and all its prerequisite libraries are available to it, then the `pirt.pl` script will attempt to follow these steps:

* Load the file `next_digit.txt` to see which digit of pi it is currently interested in.

* Fetch that digit from the file `pi.txt`. (It considers the decimal point a "digit".)

* Search twitter for tweets that contain the English-language word for that digit. (The decimal point results in a search for "point".)

* If the results of this search contain a tweet that matches all these criteria...

    * It begins with the digit-word

    * It does not contain any words from a lengthy (and rather prudish) forbidden-words list

    * The tweet's ID is not in a local database of already-posted tweets

* ...then it takes these further steps:

    * Retweet that tweet.

    * Update the account's bio to reflect which digit of pi we just posted.

    * Increment the number stored in next_digit.txt.

    * Add the tweet's ID to the database of already-posted tweets.

* If those earlier criteria match no tweets from its first search attempt, the script does nothing further.

Then the script exits. It is meant to run via an automated scheduler (such as `cron`), several times per day.

## Wow this is pretty stupid, haha

Haha, yeah.

I created it on a whim on 2014. I open-sourced it in 2019 after [the BotWiki project](https://botwiki.org) invited me to submit it into its collection. It prefers open-source submissions, and it was Christmas, and I try to keep my ego burning low. So here you have it.

This is not meant to be model code, much less reusable code. It is, at best, amusable code. I hope only that it succeeds at this, for someone.

## Running it yourself

Obviously I'd prefer it if you didn't run my bot exactly as it is and
take credit for it, at least as long as @AcrosticPi still seems to be
extant and active. But I would welcome folks messing around with it to
learn more about how Twitter bots work, or whatnot.

### Installating prerequisites 

Acrostic Pi is written in Perl, and makes use of a variety of free code libraries available from the CPAN. You will probably need to install some or all of them in order to get the script to work.

If you enjoy blindly running `curl | bash` invocations straight off of GitHub README files as much as I do, then you can just do this:

    curl -fsSL https://cpanmin.us | perl - --installdeps .
    
More conservative users can install [cpanm](https://github.com/miyagawa/cpanminus) manually and then run `cpanm --installdeps .` instead.

## Configuration

See the included file `pirt.config.example` and follow its instructions to create the mandatory config file.

## Running

You must provide a `config` command-line argument that points to the required configuration file, like so:

    ./pirt.pl --config=/path/to/pirt.config

Some optional arguments:

* **verbose**: If this is set, then if the script can't find an appropriate tweet to retweet -- a rather common occurrence, really -- then it will emit a warning admitting as much. If not set, then it will instead exit silently.

* **debug**: The script will print random muttering about stuff while it works so you can take a look at what it's doing, allegedly.

## Author

Jason McIntosh (<https://jmac.org>)

## Copyright and license

This work is copyright (c) 2019 by Jason McIntosh, and distrubited under the MIT License. (See the file LICENSE.)
