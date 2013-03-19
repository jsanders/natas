## What This Is

My solutions to the [Natas Wargame](http://www.overthewire.org/wargames/natas/) created
by the kind folks at OverTheWire.

### [0](http://natas0.natas.labs.overthewire.org/)

View source

### [1](http://natas1.natas.labs.overthewire.org/)

View source without right click

### [2](http://natas2.natas.labs.overthewire.org/)

Note there is a pixel image in files/pixel.png.
See if there is a files/ listing. There is.
Password in files/users.txt

### [3](http://natas3.natas.labs.overthewire.org/)

This one was hard - note the hint about Google.
Check for robots.txt in root. It's there.
Disallows /s3cr3t/, which contains users.txt

### [4](http://natas4.natas.labs.overthewire.org/)

Disallowed because referer isn't right.
Forge referer in some fasion (I used curl).

### [5](http://natas5.natas.labs.overthewire.org/)

Claims not logged in. Check cookie. Plain text.
Change cookie somehow:
  `document.cookie = "logged_in=1";`
  `curl blah -H 'Cookie: logged_in=1'`

### [6](http://natas6.natas.labs.overthewire.org/)

Follow link to source which contains PHP.
Maybe we can access includes/secret.inc directly.
Yep.

### [7](http://natas7.natas.labs.overthewire.org/)

Sort of a fun one. Follow the "Home" and "About" links.
Note what they do to URL. Try something else in the query.
"No such file or directory". Check out with some "../"s.
Traverse your way back to /etc/natas_webpass/natas8

### [8](http://natas8.natas.labs.overthewire.org/)

Pretty weak encryption :)
`Base64.decode64([encoded_string].pack('H*').reverse)`

### [9](http://natas9.natas.labs.overthewire.org/)

Another fun one! Look at source. Note execution of user data.
End grep, cat password file, ignore original grep argument:
`blah blah; cat /etc/natas_webpass/natas10 #`

### [10](http://natas10.natas.labs.overthewire.org/)

Ok we can't do cat now, but we can grep in whatever we want.
Let's guess that the password contains an 'a':
`a /etc/natas_webpass/natas11 #`

### [11](http://natas11.natas.labs.overthewire.org/)

This one looks a bit harder. The cookie is "encrypted" with a simple
XOR based scheme using a key we don't know. We know the scheme, and we
can set the bgcolor to different values and see how it changes the cookie.
I'm guessing we can figure out the key from those two pieces of data.
Alright this wasn't particularly pretty. I base64 decoded the cookies for
a bgcolor of 000000 and ffffff, then converted that to hex and eye-balled
the bytes that were different in the two cookies. I grabbed those bytes and
XORed them with what I knew the characters should be (either 'f' or '0'):

```irb
>> fffdi
=> "115e2c17115e"
>> fffkey = []; [fffdi].pack('H*').each_byte { | b | fffkey << (b ^ 'f'.ord) }; fffkey.map(&:chr)
=> ["w", "8", "J", "q", "w", "8"]
```

I sort of suspected we'd find that the key was short enough to repeat in the
six characters of the bgcolor, and sure enough, it is "w8Jq".

Oh, duh, of course there's no reason the key has to start at 'w'. Try all
four variants to see which makes the original 'ffffff' cookie properly.
Turns out it is 'qw8J'. Use a copy of xor_encode (provided as xor_encode.php)
with the right key to run cookie creation functions from original source:
`echo base64_encode(xor_encrypt(json_encode(array("showpassword"=>"yes", "bgcolor"=>"#ffffff"))));`

Now we can set the cookie ourselves:
`document.cookie = "data=ClVLIh4ASCsCBE8lAxMacFMOXTlTWxooFhRXJh4FGnBTVF4sFxFeLFMK";`

### [12](http://natas12.natas.labs.overthewire.org/)

Initial thoughts - try to move the password file to the uploads directory.
Spent some time trying to see how to break the random file name generation,
but since it only uses the extension from the filename I can control, and not
the rest of the name, that isn't working. However, I did notice that it doesn't
check the extension! New thought: upload a php file and browse to it.

Worked like a charm, saved as echo_natas_13_pw.php.

### [13](http://natas13.natas.labs.overthewire.org/)

Pretty stumped on this one - it is now checking for !exif_imagetype. I don't
immediately know how to break that function without doing some searching.
Currently trying to make my php file look like a jpeg and hoping it still parses.
Not working though. Gonna go take a look at the source for that function.

HOLY SHIT IT WORKED

Found the [jpg signature used by exif_imagetype](https://github.com/php/php-src/blob/master/ext/standard/image.c#L44)
Opened a hexeditor and added those three bytes to the front of the file.
Checks out as jpg, and the silly web server still runs it as php!

Saved the file as echo_natas_14_pw.php

Seems like this was pretty tough, but hey maybe we're just in the big numbers now.

### [14](http://natas14.natas.labs.overthewire.org/)

Straightforward SQLi. Make the query return something, anything.

### [15](http://natas15.natas.labs.overthewire.org/)

Ok pretty stumped here. The SQLi is obvious, but it looks like the only output
is the very information-light "This user exists/doesn't exist".

Alright long story short, we can find out what users exist by using the form
as it claims to be intended. Take a wild-ass guess that there is a user called
"natas16". There is. Now the trick is to find the password for that user. The
key insight is that we can inject a query like:
`SELECT * FROM users WHERE username="natas16" AND password LIKE "%a%"`
This tells us that there is in fact an "a" somewhere in the password. Neat.
Now we can brute force it by building it up a character at a time. Let's assume
the password is going to look like the one from the last level, which was 32
characters and contained only numbers and lower and upper case letters. With
this assumption and our ability to build the password up a letter at a time
rather than having to try every combination, we can expect to have to try each
of the 62 possible letters and numbers once for each of the 32 positions in the
password, which gives us the very achievable 1,984 possibilities in the worst case.

Oh, let's make sure to try to see if each confirmed partial password is actually
the full password, because we don't *know* it is exactly 32 characters, it could
be shorter, or up to 64.

These are the two usernames to inject, the first to find a new letter, and the
second to check if we have the full password:
`natas16" AND password LIKE "abc%`
`natas16" AND password="abcd`

Ok live and learn, MySQL's default string comparisons are case insensitive, so
I got a purely lowercase password and had to do it all over again with queries
like this:
`natas16" AND BINARY password LIKE "abc%`
`natas16" AND BINARY password="abcd`

Script included as `brute_force_16.rb`

### [16](http://natas16.natas.labs.overthewire.org/)

Bummer, we solved this one way back in 10 by being extra clever I suppose.
Let's once again guess that the password contains an 'a':
`a /etc/natas_webpass/natas17 #`

Oh! I didn't read closely enough, we also have quotes around our input.

Ok this one was pretty tough and I haven't been taking notes because for a long
time I just didn't really have a good direction, and once I did I just wrote a
bunch of code to solve it. Long story short, you can still run code using `$(...)`
which doesn't use any sanitized characters and still runs inside double quotes.
*What* code to run is the hard part. Basically, it's hard to get at the output of
any code you run, because grep uses it and doesn't give it back to you. I first
tried a bunch of commands introducing side effects that I could then see. I
noticed that you can directly read the dictionary.txt file, so I tried writing
into it - no dice, it seems to be protected. Then I played around with writing
files out to other places on the directory structure that I thought I may be able
to access. Never had any success. Then I started trying to go across the network.
I tried to send myself an email with the password, and I tried to post it to an
HTTP server I was running. Seems like outgoing requests are blocked.

I finally gave up on all that nonsense and started trying to make the grep command
itself work for me. This almost immediately bore fruit - I could find every word
containing an 'a' or a 'b' or a 'ch', and it was relatively obvious which letter
was shared amongst all the words, so I figured I could start taking subsets of the
password and looking them up in the dictionary. Initially I was manually using cut
to find strings of letters:
`$(cut -c1-1 /etc/natas_webpass/natas17)`
`$(cut -c2-3 /etc/natas_webpass/natas17)`
The first of those returned no words, which convinced me that the first character
in the password is a number, but I still had no idea which one (noticing the first
issue with this approach). The second command returned a bunch of words like 'archbishop',
'dashboard', 'highbrow', which was very promising because obviously my second and
third characters are 'h' and 'b' respectively! After being excited by this sequence
idea for awhile I realized it was silly - I could make a method that would tell me
which single letter was shared amongst all the returned words and it would almost
certainly be unique. That turned out to be true, so I wrote a little program that
would tell me whether the character in a position was a number, and if not, what
letter it was. Unfortunately this approach had two problems - first, the number
thing, I still needed to determine *which* number, and second, the grep is case
insensitive, so I didn't know whether each letter was meant to be upper-case or
lower-case. I figured that at least this was a lot of information, and brute forcing
from there would be much easier. Then I ran some numbers. I had 5 numbers, and 27
letters in my 32-character password. Each number had 10 possible values, and each
character had 2 possible values. I figured this is 10^5 * 2^27. Uh-oh, that's about
13 trillion, and we're going over HTTP!

Ok, so this was wall number two (or three, I've lost count). I need some way to
determine exactly what a character at a given position is, perhaps using my helpful
knowledge of the structure of the password from the last step. It's at this point
that I realize that '[', ']', '-', and newlines are not stripped. That means we can
multiline bash conditionals (or so I suspected, though goodness knows I can't actually
remember bash syntax due to my being a lowly mortal and bash syntax being absolute
garbage - anyway, I looked it up). So, if we can create a conditional block that gives
us an indication of success or failure using the grep command, we can run that for
each position. After much finagling:
```sh
$(echo $(if [ $(cut -c1-1 /etc/natas_webpass/natas17) = 0 ]
then
echo h
else
echo qq
fi))
```
What that command says is "if the first character of the password is '0', output an
'h' character, otherwise output 'qq'". Basically it outputs something that *does*
exist in at least one word in the dictionary if the characters match, and something
that *doesn't* if they don't match. I have no clue if that outer `$(echo ...)` is
needed - it seems like it shouldn't be, but it works this way, so let's not tempt
fate, eh?

The rest is just bookkeeping :) Code for all my various solutions in `brute_force_17.rb`.
