<h2>Developer's
Guide
</h2>

<h3>Introduction</h3>

<p>So you want to dig into the PsN code. Maybe you want to write a new
tool for the toolkit or just learn more about PsN. Either way, here you
will find what you need to learn how to use PsN as well as writing nice
maintainable and readable code in the spirit of PsN.
</p>
<p>To
fully apprecieate this document
you should have some coding
experience and should have worked with object oriented programming. If
you know about UML and XML that is a bonus. If you don't know about
these fancy things, don't sweat it, We'll try to keep it as simple as
possible.</p>
<h3>Dia and Dia2Code</h3>
<p>
PsN is written in <a target="_blank" href="http://www.perl.org/">Perl</a>.
Perl is powerful, good at text manipulation and system interaction and
is
very flexible. A little too flexible for a piece of software the size
of
PsN. When we took the first steps to making PsN object oriented we felt
that defining the object structure in Perl was a bit cumbersome. Also,
Perl lacks type-checking, which very much eases debugging. Adding that
manually for accessors and methods in all of PsN's classes would be
time-consuming and probably wouldn't be done homogenously and it would be
difficult
to maintain. Our answer to these hurdles is <a target="_blank"
 href="http://www.gnome.org/projects/dia/">Dia</a>.
Dia is a GTK+ based diagram creation program released under the GPL
license. </p>
<p>With
Dia, we have created UML
diagrams for all classes in PsN. Dia saves
its diagrams in XML format. This allows us to generate code through <a
 target="_blank" href="http://dia2code.sourceforge.net/">Dia2Code</a>.
Dia2Code is a small utility used to generate code from a Dia diagram.
Dia2Code didn't support Perl, so we added a plugin to it that generates
appropriate code. It gave us freedom in how we do type checking, and
how accessors
and methods are created. </p>
<p> In order to produce
usable PsN code from the diagrams it takes three steps. </p>
<ol>
  <li>
    <div style="text-align: justify;">
    <p> The first is to
create a Dia UML diagram that defines classes complete with typed
members, methods and inheritance between classes.</p>
    </div>
    <!--<p style="text-align: justify;">Read
our <a href="dia_index.php">Dia
UML guide</a> for details. -->You can
also have a look at the Dia authors' <a target="_blank"
 href="http://www.gnome.org/projects/dia/diatut/all/all.html">tutorial</a>
on how to use Dia. </p>
    <p> </p>
  </li>
  <li>
    <p style="text-align: justify;">The
second step is to
add code that goes into the class structure skeleton generated by
Dia2Code. As described in step three.</p>
    <p style="text-align: justify;">Dia2Code
will, for
each class, generate a constructor(a method named "new"), a skeleton
for each class method and accessors for each class member. Each members
accessor can take one argument, that argument will then be set as the
new value for the member. If no argument is given, the accessor will
return the current value of the accessor. </p>
    <p style="text-align: justify;">Both
accessors and
constructor are in fact perl methods, but since
Dia2Code writes slightly different skeletons for them, we give them
different names to ease discussion. </p>
    <p style="text-align: justify;">
Now, for every
method you can add your own code (Otherwise it would be rather
pointless, wouldn't it). You can also add code to the constructur, and
to accessors (something we don't do much, but there are cases where it
might be useful). </p>
    <p style="text-align: justify;">To
add your own code you
must create a file parallel to the file
generated by Dia2Code. So, for example, we can look the class <tt>"problem"</tt>
defined in <tt>"model.dia"</tt>.
Dia2Code would generate the file: </p>
    <blockquote>
      <p class="style2"><tt>[
Path to PsN Diagrams ]lib/model/problem.pm</tt><br>
      </p>
    </blockquote>
Then you should create the file:
    <blockquote>
      <p class="style2"><tt>[
Path to PsN Diagrams ]lib/model/problem_subs.pm</tt><br>
      </p>
    </blockquote>
    <p style="text-align: justify;">The
extension <tt>_subs</tt>
and the <tt>"lib"</tt>
directory is just a convention, you
can call it whatever you like, but if you want to use our makefile
script described in step three, you should add <tt>_subs</tt>
to the filename
and put it in the <tt>"lib"</tt>
directory. It will make life easier. </p>
    <p>Note that you should keep
the <tt>.pm</tt>
extension.</p>
    <p style="text-align: justify;">
In the <tt>_subs</tt>
file
you add a block of code for each method you need to add. Each block
must start with <tt>"start
method_name"</tt> and end with <tt>"end
method_name"</tt>,
Everything in between must be valid Perl code. A typical block might
look like this: </p>
    <blockquote>
      <p><tt>start
nthetas<br>
{<br>
# returns the number of thetas in the model for the given<br>
# problem number.<br>
$nthetas = $self -&gt; _parameter_count( 'record' =&gt;
'theta', <br>
'problem_number' =&gt; $problem_number );<br>
}<br>
end nthetas</tt></p>
    </blockquote>
    <p style="text-align: justify;">What
you notice from the
example is that you have accecss to any
argument that was defined for the method in the Dia diagram. And the <tt>$self</tt>
variable which is a reference to the class instance from which
the
method was called (comparable to the <tt>"this"</tt>
variable in C++).</p>
    <p style="text-align: justify;">In
the code block for
accessors
you have access to the variable <tt>$parm</tt>
which is the given argument, if any. And in the constructor block(the
special method named <tt>"new"</tt>),
    <tt>$self</tt>
is called <tt>$this</tt>
for some obscure
reason, this might change.</p>
    <p> </p>
  </li>
  <li>
    <div style="text-align: justify;"></div>
    <p style="text-align: justify;">The
final step is to
compile the diagrams and <tt>_subs</tt>
files into a functional PsN library. If
you have everything installed in place and have not added any new Perl
files or diagrams you only need to run make from the diagrams
directory. If you have added new files or new classes(which implicitly
means Dia2Code will generate files for them) you must add those files
to the makefile.</p>
    <p style="text-align: justify;">
You can also choose
to run Dia2Code manually. Assuming that you have Dia2Code installed and
working you should start your shell and go to the directory where you
created the Dia file and type the following: </p>
    <blockquote>
      <p class="style2"><tt>dia2code
-t perl file.dia</tt></p>
    </blockquote>
    <p style="text-align: justify;">Dia2Code
will generate a
file called <tt>"class.pm"</tt>
for each defined class.
In each it has defined a Perl package, a constructor (called <tt>new</tt>),
a
method and an accessor.</p>
    <p style="text-align: justify;">
You can now editing
this file and add your own code to the skeleton. Notice though, that
the file will be overwritten each time you run Dia2Code. We have solved
this with a script called fill_diacode.pl that takes code from <tt>file_subs.pm</tt>
and puts it into the <tt>file.pm</tt>
file generated by Dia. To use <tt>fill_diacode.pl</tt>
type: </p>
    <blockquote>
      <p class="style2"><tt>fill_diacode.pl
file_subs file.pm</tt></p>
    </blockquote>
    <p style="text-align: justify;">Now
file.pm contains all
code and should be ready to run. I suggest you
also have perl check it for syntax errors (and enable warnings):</p>
    <blockquote>
      <p class="style2"><tt>perl
-c -W -t -T file.pm</tt></p>
    </blockquote>
  </li>
</ol>
<p>Now
you should at least have an
overview of how the system is thought
out to work. If you find any inconsistencies or even errors (I'm sure
there are), please don't be afraid to contact us with questions.</p>
<h3>Coding
Style and Conventions</h3>
<p style="text-align: justify;">
Since there are several
developers working on PsN, we have tried to conform to a coding
standard. It is not
100% enforced throughout PsN and it is not expected that you follow our
recommendations to the extreme. Consider our recommendations as
friendly guidelines to something we think is readable code. </p>
<ul>
  <li>
    <div style="text-align: justify;"><span style="font-weight: bold;">Variables</span>
- We don't mind
long variables, several words are more than OK. But try to limit
yourself to four or five words. And for the love of God, don't write
them together and capitalize letters, like so: <tt>$thisIsALongAndHardToReadVariableName</tt>.
Instead separate word with and
underscore and keep them lowercase, like this: <tt>$nice_readable_variable</tt>.
    <p>Long
variable names are
only needed when the use of the varible is not entirely clear and is
used in a long scope (such as an entire function). In other cases
shorter names are allowed (and encouraged) such as <tt>$i</tt>,
    <tt>$temp</tt>
or even <tt>$string</tt>.</p>
    </div>
  </li>
  <li>
    <p>when it is obvious how the
variable is intended to be used. </p>
  </li>
  <li>
    <div style="text-align: justify;"><span style="font-weight: bold;">Loops</span>
- In Perl it is easy
to write loops with the powerful <tt>foreach</tt>
construct. Try to use them as
much as you can. In cases where you need an index in the loop, use <tt>$i</tt>
as loop variable and keep initial values and loop conditions simple.
    </div>
  </li>
  <li>
    <p><span style="font-weight: bold;">Conditions</span>
- Avoid the <tt>"
cond ? this : that"</tt> constructs,
they are hard to read!</p>
  </li>
  <li style="text-align: justify;">
    <p><span style="font-weight: bold;">Methods</span>
- Method names
should be similar to variable names, and should start with double
underscores if they are private.</p>
  </li>
</ul>
<h3>Error
Handling</h3>
<p style="text-align: justify;"> To simplify debugging a bit we
have created a wrapper around Perl's Carp module. Every Perl file
genereted with our perl plugin for Dia2Code uses it. </p>
<p style="text-align: justify;"> It is a common Perl module
and
you include it with <tt>use debug;</tt>.
Then you have a few methods to print warning messages and die with a
bit more detailed error message than is produced by perl <tt>die</tt>
function. </p>
<p style="text-align: justify;"> The Debug class is a little
bit special in that it should never be instantiated. An instance is
kept globally which can be accessed by the members of the debug class
if they are called statically. Calling a member statically means that
you adress them using the Perl module name, for example:</p>
<p style="text-align: justify;"> <tt>debug
-&gt; level( );</tt></p>
<p style="text-align: justify;"> Notice that there is no $ in
front of 'debug'. Here level is called "statically". In other words, it
means "call a member without an instance".</p>
<p style="text-align: justify;"> The reason for this is that
debug keeps a "level" variable globaly, which indicates how verbose PsN
should be, the higher the level, the more messages you will see. The
level variable is numerical, but each level has a name in order to make
its use a bit more intuitive. The levels are, starting with the lowest:</p>
<p style="text-align: justify;"></p>
<dl style="text-align: justify;">
  <dt style="font-weight: bold;">"fatal"</dt>
  <dd>only when an error so grave
that PsN has to exit, a fatal message may be printed. This is the least
amount of messages you can see.</dd>
  <dt style="font-weight: bold;">"warning"</dt>
  <dd>When something critical
happens, somethings that probably should be examined closer, though not
serious enough to exit PsN a warning message may be printed.</dd>
  <dt style="font-weight: bold;">"information"</dt>
  <dd>When something out of the
ordinary happens and we think the user should be informed, an
informational message may be printed.</dd>
  <dt style="font-weight: bold;">"call_trace"</dt>
  <dd>This level is mostly used by
developers when debugging PsN. If this level is set a message will be
printed for each method which is called inside PsN. Needless to say,
this will print a lot of text. The only time a user should turn this is
when filing a bug report, and only then if a developer thinks it is
necessary.</dd>
</dl>
<div style="text-align: justify;">Setting a higher level than "fatal"
also means that message of all
lower levels will be printed.
</div>
<p style="text-align: justify;"> No PsN class may change the
level. </p>
<p style="text-align: justify;"> The methods available debug
are:</p>
<p style="text-align: justify;"> </p>
<dl>
  <dt style="text-align: justify;"><b>level(
)</b></dt>
  <dd style="text-align: justify;">If you give a value to level
as a single argument, you will set the global level of debug messages.
    <p> <tt>debug
-&gt; level( debug::warning )</tt></p>
    <p> If you don't give any
argument the current level is returned. </p>
    <p> <tt>my
$current_level = debug -&gt; level</tt></p>
    <p> </p>
  </dd>
  <dt style="text-align: justify;"><b>package(
)</b></dt>
  <dd style="text-align: justify;">If you give a value to
package as a single argument, you will set the global package of debug
messages. If you don't give any argument the current package is
returned.
    <p> <tt>my
$current_package = debug -&gt; package</tt></p>
    <p> </p>
  </dd>
  <dt style="text-align: justify;"><b>subroutine(
)</b></dt>
  <dd style="text-align: justify;">If you give a value to
subroutine as a single argument, you will set the global subroutine of
debug messages.
    <p> <tt>debug
-&gt; subroutine( 'output' )</tt></p>
    <p> If you don't give any
argument the current subroutine is returned. <tt>my
$current_subroutine = debug -&gt; subroutine</tt></p>
    <p> </p>
  </dd>
  <dt style="text-align: justify;"><b>level_name(
)</b></dt>
  <dd style="text-align: justify;"><span style="font-family: monospace;">level_name</span>
will map an
integer in the interval 0 to 3 to a string. The string is the name of
the level with that number in the order of levels. ( <span
 style="font-family: monospace;">"fatal"</span>
is lowest
and <span style="font-family: monospace;">"call_trace"</span>
highest ).
    <p> <tt>my
$level_name = debug -&gt; level_name( level =&gt; 1 )</tt></p>
    <p> By default it returns the
name of the current set level.</p>
    <p> <tt>my
$current_level_name = debug -&gt; level_name;</tt>
    </p>
  </dd>
  <dt style="text-align: justify;"><b>warn_with_trace(
)</b></dt>
  <dd style="text-align: justify;">By default, a trace of
function calls is printed when PsN dies. If you like you can set a
level for which you like traces to be printed. Notice that all lower
level messages will also have a trace printed after them.
    <p> <tt>debug
-&gt; warn_with_trace( debug::warning )</tt>
    </p>
  </dd>
  <dt style="text-align: justify;"><b>warn(
)</b></dt>
  <dd style="text-align: justify;"><span style="font-family: monospace;">debug::warn</span>
will print out
warning, informational or call_trace messages corresponding to the
level specified as argument. <tt>debug::warn</tt>
will look at the level given
and the global level to see whether anything should be printed.
    <p> <tt>debug
-&gt; warn( level =&gt; debug::warning, message =&gt; "This
is a warning" );</tt></p>
    <p> NOTICE the lack of <tt>"\n"</tt>
at
the end of the message, <tt>debug::warn</tt>
will append one <tt>"\n"</tt>.
In case there ever is a GUI for PsN <tt>debug::warn</tt>
could be used to create a message in the GUI. And in that
case, an extra <tt>"\n"</tt>
might be annoying. </p>
  </dd>
  <dt style="text-align: justify;"><b>die(
)</b></dt>
  <dd>
    <div style="text-align: justify;"><span
 style="font-family: monospace;">debug::die</span>
is what PsN calls
instead of <span style="font-family: monospace;">"die"</span>
in order to get a call trace. The given message is
allways printed.
    </div>
    <p style="text-align: justify;"> <tt>debug
-&gt; die( message =&gt; "This message will print, and then PsN
will die" );</tt></p>
    <p style="text-align: justify;"> NOTICE the lack of <span
 style="font-family: monospace;">"\n"</span>
at
the end of the message, <span style="font-family: monospace;">debug::warn</span>
will append one <span style="font-family: monospace;">"\n"</span>.
In case there
ever is a GUI for PsN debug::doe could be used to create a message in
the GUI. And in that case, an extra <span
 style="font-family: monospace;">"\n"</span> might be annoying. </p>

