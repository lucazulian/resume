%----------------------------------------------------------------------------------------
% class configuration
%----------------------------------------------------------------------------------------

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{developercv}[2021/01/24 developer-cv class v1.0]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{extarticle}}
\ProcessOptions\relax

\LoadClass{extarticle}

%----------------------------------------------------------------------------------------
% packages and other document configuration
%----------------------------------------------------------------------------------------

\setlength{\parindent}{0mm}

\usepackage[hidelinks]{hyperref}

% Text extraction (ATS, LLMs, copy/paste): map glyphs to Unicode and
% keep words intact (no hyphenation, no stretched inter-word glue)
\input{glyphtounicode}
\pdfgentounicode=1
\hyphenpenalty=10000
\exhyphenpenalty=10000
\tolerance=9999
\emergencystretch=3em

% Replace the text extracted from #2 with #1 (ASCII only, no parentheses)
\newcommand{\actualtext}[2]{%
	\pdfliteral direct{/Span <</ActualText (#1)>> BDC}%
	#2%
	\pdfliteral direct{EMC}%
}

\pagestyle{empty}

\usepackage{moresize}

%----------------------------------------------------------------------------------------
% page layout
%----------------------------------------------------------------------------------------

\usepackage{geometry}

\geometry{
	paper=a4paper,
	top=1.2cm,
	bottom=1.2cm,
	left=1.8cm,
	right=1.8cm,
	headheight=0.75cm,
	footskip=1cm,
	headsep=0.5cm,
	%showframe, % Uncomment to show how the type block is set on the page
}

%----------------------------------------------------------------------------------------
% fonts
%----------------------------------------------------------------------------------------

\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}

\usepackage[default]{raleway}

\renewcommand*\familydefault{\sfdefault}

% slightly tighter leading to keep the CV on two pages
\linespread{0.95}

\usepackage{fontawesome}

% \icon{FontAwesome name}{size}{text label for extraction}{content}
\newcommand{\icon}[4]{%
	\vcenteredhbox{\actualtext{#3: }{\colorbox{black}{\makebox(#2, #2){\textcolor{white}{\large\csname fa#1\endcsname}}}}}
	\hspace{0.2cm}
	\vcenteredhbox{\textcolor{black}{#4}}
}

%----------------------------------------------------------------------------------------
% graphics definitions
%---------------------------------------------------------------------------------------- 

\usepackage{tikz}
\usetikzlibrary{shapes, backgrounds}
\tikzset{x=1cm, y=1cm}

\newcommand{\vcenteredhbox}[1]{
	\begingroup
		\setbox0=\hbox{#1}\parbox{\wd0}{\box0}
	\endgroup
}

%----------------------------------------------------------------------------------------
% charts
%---------------------------------------------------------------------------------------- 

\newcounter{barcount}

\newenvironment{barchart}[1]{
	\newcommand{\barwidth}{0.35}
	\newcommand{\barsep}{0.2}
	
	\newcommand{\baritem}[2]{
		\pgfmathparse{##2}
		\let\perc\pgfmathresult
		
		\pgfmathparse{#1}
		\let\barsize\pgfmathresult
		
		\pgfmathparse{\barsize*##2/100}
		\let\barone\pgfmathresult
		
		\pgfmathparse{(\barwidth*\thebarcount)+(\barsep*\thebarcount)}
		\let\barx\pgfmathresult
		
		\filldraw[fill=black, draw=none] (0,-\barx) rectangle (\barone,-\barx-\barwidth);
		
		\node [label=180:\colorbox{black}{\textcolor{white}{##1}}] at (0,-\barx-0.175) {};
		\addtocounter{barcount}{1}
	}
	\begin{tikzpicture}
		\setcounter{barcount}{0}
}{
	\end{tikzpicture}
}

%------------------------------------------------

\newcounter{a}
\newcounter{b}
\newcounter{c}

\newcommand{\bubbles}[1]{
	\setcounter{a}{0}
	\setcounter{c}{150}
	
	\begin{tikzpicture}[scale=3]
		\foreach \p/\t in {#1} {
			\addtocounter{a}{1}
			\bubble{\thea/2}{\theb}{\p/25}{\t}{1\p0}
		}
	\end{tikzpicture}
}

\newcommand{\bubble}[5]{
	\filldraw[fill=black, draw=none] (#1,0.5) circle (#3);
	\node[label=\textcolor{black}{#4}] at (#1,0.7) {};
}

%----------------------------------------------------------------------------------------
% custom sections
%----------------------------------------------------------------------------------------

\newcommand{\cvsect}[1]{
	\vspace{0.7\baselineskip}
	\colorbox{black}{\textcolor{white}{\MakeUppercase{\textbf{#1}}}}\\
}

%----------------------------------------------------------------------------------------
% entry list
%----------------------------------------------------------------------------------------

\usepackage{longtable}
\setlength{\LTpre}{0pt}
\setlength{\LTpost}{0pt}

\setlength{\tabcolsep}{0pt}

\newenvironment{entrylist}{
	\begin{longtable}[H]{l l}
}{
	\end{longtable}
}

% \entry{dates / place}{title}{organisation}{description (may be empty)}
\newcommand{\entry}[4]{%
	\def\entrydesc{#4}%
	\parbox[t]{0.175\textwidth}{%
		\raggedright
		#1%
	}%
	&\parbox[t]{0.825\textwidth}{%
		\raggedright
		\textbf{#2}%
		\hfill
		{\footnotesize \textbf{\textcolor{black}{#3}}}%
		\ifx\entrydesc\@empty\else\\#4\fi
		\par\vspace{\entrygap}%
	}\\}

% build month and year, British style (e.g. "October 2026")
\newcommand{\monthyear}{%
	\ifcase\month\or January\or February\or March\or April\or May\or June\or
	July\or August\or September\or October\or November\or December\fi
	\ \the\year}

% vertical space below each entry
\newlength{\entrygap}
\setlength{\entrygap}{0.5em}

\newcommand{\slashsep}{\hspace{3mm}/\hspace{3mm}}
