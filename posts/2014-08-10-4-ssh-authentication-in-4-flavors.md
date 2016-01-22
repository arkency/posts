---
title: "SSH authentication in 4 flavors"
created_at: 2014-08-10 13:00:20 +0200
kind: article
publish: true
author: Kamil Lelonek
newsletter: :skip
newsletter_inside: :fearless_refactoring_1
tags: [ 'authentication', 'ssh', 'security' ]
---

<p>
  <figure align="center">
    <img src="<%= src_fit("ssh-authentication/ssh-authentication.jpg") %>" width="100%">
  </figure>
</p>

We are connecting with remote servers every day. Sometimes we explicitly provide passwords, sometimes it just happens without it. A lot of developers don't care how it works internally, they just get access, so why to bother at all. **There are a couple ways of authentication, which are worth to know** and I'd like to present you them briefly.

<!-- more -->

Each authentication method requires some setup on the very beginning. Once it's done, we can forget about it and connect without any further configuration. However **there are different ways to configure authentication on your server** with different secure level and initial setup process. Let's review the most common.

> The SSH authentication protocol is a general-purpose user authentication protocol.  It is intended to be run over the SSH transport layer protocol. This protocol assumes that the underlying protocols provide integrity and confidentiality protection.<br>
<small>From: http://tools.ietf.org/html/rfc4252</small>

## Ordinary password authentication

1. User makes initial connection and sends a username as a part of SSH protocol.
2. Server SSH daemon responds with password demand.
3. SSH client prompts for password, which is transported through encrypted connection.
4. If passwords match, access is granted and secure connection is established to a login shell.

**Pros:**

- Simple to set up
- Easy to understand

**Cons:**

- Brute force prone
- Each time password entering

## Public key access

Prerequisites are that **user creates a pair of public and private keys**. 

> Private keys are often stored in an encrypted form at the client host, and the user must supply a passphrase before the signature can be generated. Even if they are not, the signing operation involves some expensive computation.
<br><small> From: http://tools.ietf.org/html/rfc4252#page-9 </small>

Then, public key is added to `$HOME/.ssh/authorized_keys` on a server. That may be done via[ `ssh-copy-id`](http://manpages.ubuntu.com/manpages/lucid/man1/ssh-copy-id.1.html). You can read [nice tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2) describing it quite well.

Connection itself:

1. User makes initial call with username and request to authenticate using key.
2. Server SSH daemon creates some challenge based on `authorized_keys` file and sends it back to SSH client.
3. SSH client looks for user's private key encrypted by passphrase and prompts user for it.
4. After user enters matching password, response for server is being created using that private key.
5. Server validates the response and grants access to the system.

**Pros:**

- Using passphrase instead of password, which is identical for multiple servers with your public key in  `authorized_keys`
- Public keys cannot be easily brute-forced

**Cons:**

- More steps behind the scenes
- More complicated first-time configuration

## Public key access with agent support

Both of previous methods was equally cumbersome because of necessity to enter password or passphrase each time we want co connect. This may be tedious when we communicate often with our remote servers.

**Key agent** provided by SSH suite comes with help, because it **can hold private keys for us**, and responds to request from remote systems. Once unlocked, it allows to **connect without prompting for credentials** anymore.

1. User makes initial call with username and request to authenticate using key.
2. Server SSH daemon creates some challenge based on `authorized_keys` file and sends it back to SSH client.
3. SSH client after receiving key challenge, forwards it to agent, which opens user's private key.
4. User sees one-time prompt for the passphrase to unlock the private key.
5. Key agent constructs the response based on received challenge and sends it back to SSH, which does not know anything about private key at all.

**Pros:**

- Does not prompt for password each time, but only the first time
- SSH doesn't have access to private key, which never leaves the agent

**Cons:**

- Requires additional key agent setup
- If remote server makes some further connection to ssh servers elsewhere, it requires either password access or private key on our remote server

## Public key access with agent forwarding

This last way is the most perfect of all above, because it gets rid of the second disadvantage in almost ideal previous method. Instead of requiring passwords or passphrases on intermediate servers, it **forwards request**, through chained connections, **back to initial key agent**.

1. We are connected and authenticated in the same way as in previous method already
2. Our remote server (*Foo*) makes remote call to another one (let's name it *Bar*) and connection requires provisioning using key.
3. SSH daemon residing in *Bar* constructs a key challenge based on its own `authorized_keys` file.
4. When SSH client on *Foo* receives challenge, it **forwards that challenge to SSH daemon on the same machine**. Now `sshd` can pass received challenge down to original client that invoked the initial call.
5. The agent running on home machine constructs a response and hands it as a response to *Foo* server.
6. Now *Foo* connects back to *Bar* and answers with challenge solution. If it's valid, access is granted.

For better understanding and real-life example, let's imagine that this second connection may be some kind of `scp` or `sftp` transfer.

**Pros:**

- No need to struggle with irritating prompts anymore

**Cons:**

- Requires public keys installation on targeted systems

## More about key negotiation

In order to connect with SSH server and authenticate using your public/private keypair, you have to first share your public key with the server. As we described before, that can be done using [`ssh-copy-id`](https://github.com/beautifulcode/ssh-copy-id-for-OSX) or some script

```
#!bash
#!/bin/sh

KEY="$HOME/.ssh/id_rsa.pub"

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "Public key not found at $KEY"
    echo "* please create it with "ssh-keygen -t dsa" *"
    echo "* to login to the remote host without a password. *"
    exit
fi

if [ -z $1 ]; then
    echo "Please specify user@host as the first switch to this script"
    exit
fi

echo "Putting your key on $1... "

KEYCODE=`cat $KEY`
ssh -q $1 "mkdir ~/.ssh 2>/dev/null; \
          chmod 700 ~/.ssh; \
          echo "$KEYCODE" >> ~/.ssh/authorized_keys; \
          chmod 644 ~/.ssh/authorized_keys"

echo "done!"
```

Once it's done, server can construct some challenge based on your public key. Because RSA algorithm is asymmetric, message encrypted using public key can be decrypted using private key and opposite.

Key negotiaton may be as follows: client receives a message encrypted by your public key and can decrypt it using your private key. Next, it encrypts this message with server public key and sends back to server, which uses its own private key to decrypt and validates if message matches this sent one initially.

Of course the above flow is only the example of how challenges may works. They are often more complicated and contain some MD5 hashing operations, session IDs and randomization, but the general rule is really similar. [RFC](http://tools.ietf.org/html/rfc4252#page-9) offers far more comprehensive explanation of this whole process.

What is worth to know, there are to versions (v1 and v2) of SSH standard. According to [OpenSSH's ssh-agent protocol](http://api.libssh.org/rfc/PROTOCOL.agent):

> Protocol 1 and protocol 2 keys are separated because of the differing cryptographic usage: protocol 1 private RSA keys are used to decrypt challenges that were encrypted with the corresponding public key, whereas protocol 2 RSA private keys are used to sign challenges with a private key for verification with the corresponding public key. It is considered unsound practice to use the same key for signing and encryption.

Note that **private key belongs only to you** and is **never** shared anywhere. 

## Possible threats

As I described before, the basic benefit of using SSH agents is to protect your private key without need to expose it anywhere. The weakest link is SSH agent itself. Any kind of implementation must provide some way that allows to make request from client, some kind of interface to interact with. It's usually done with UNIX socket accessible via file API. Although this socket is heavily protected by the system, nothing can really prevent from accessing it by `root`. Any key agent set by `root` has immediately granted necessary permissions so there's no method preventing `root` user from hijacking SSH agent socket. It may not be the best solution to connect with *Bar* server when *Foo* cannot be entirely trusted.

## Summary

Now you see how authentication works and what are the ways to set it up. You may choose any configuration based on your needs, it's advantages and drawbacks. Let's secure your server without any fear now. Hope you find this useful.

<%= inner_newsletter(item[:newsletter_inside]) %>

## Resources
- http://www.unixwiz.net/techtips/ssh-agent-forwarding.html
- https://help.ubuntu.com/14.04/serverguide/openssh-server.html
- https://help.ubuntu.com/community/SSH/OpenSSH/Configuring
- http://tools.ietf.org/html/rfc4252