"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[556],{3905:(e,t,n)=>{n.d(t,{Zo:()=>p,kt:()=>k});var l=n(67294);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var l=Object.getOwnPropertySymbols(e);t&&(l=l.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,l)}return n}function r(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function o(e,t){if(null==e)return{};var n,l,a=function(e,t){if(null==e)return{};var n,l,a={},i=Object.keys(e);for(l=0;l<i.length;l++)n=i[l],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(l=0;l<i.length;l++)n=i[l],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var d=l.createContext({}),m=function(e){var t=l.useContext(d),n=t;return e&&(n="function"==typeof e?e(t):r(r({},t),e)),n},p=function(e){var t=m(e.components);return l.createElement(d.Provider,{value:t},e.children)},u={inlineCode:"code",wrapper:function(e){var t=e.children;return l.createElement(l.Fragment,{},t)}},c=l.forwardRef((function(e,t){var n=e.components,a=e.mdxType,i=e.originalType,d=e.parentName,p=o(e,["components","mdxType","originalType","parentName"]),c=m(n),k=a,s=c["".concat(d,".").concat(k)]||c[k]||u[k]||i;return n?l.createElement(s,r(r({ref:t},p),{},{components:n})):l.createElement(s,r({ref:t},p))}));function k(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var i=n.length,r=new Array(i);r[0]=c;var o={};for(var d in t)hasOwnProperty.call(t,d)&&(o[d]=t[d]);o.originalType=e,o.mdxType="string"==typeof e?e:a,r[1]=o;for(var m=2;m<i;m++)r[m]=n[m];return l.createElement.apply(null,r)}return l.createElement.apply(null,n)}c.displayName="MDXCreateElement"},26437:(e,t,n)=>{n.r(t),n.d(t,{contentTitle:()=>r,default:()=>p,frontMatter:()=>i,metadata:()=>o,toc:()=>d});var l=n(87462),a=(n(67294),n(3905));const i={},r=void 0,o={type:"mdx",permalink:"/libraries/CHANGELOG",source:"@site/pages/CHANGELOG.md",description:"2022-07-08",frontMatter:{}},d=[{value:"2022-07-08",id:"2022-07-08",level:2},{value:"Added",id:"added",level:3},{value:"Changed",id:"changed",level:3},{value:"2022-07-07",id:"2022-07-07",level:2},{value:"Added",id:"added-1",level:3},{value:"Changed",id:"changed-1",level:3},{value:"2022-07-03",id:"2022-07-03",level:2},{value:"Added",id:"added-2",level:3},{value:"Changed",id:"changed-2",level:3},{value:"2022-07-02",id:"2022-07-02",level:2},{value:"Changed",id:"changed-3",level:3},{value:"2022-07-01",id:"2022-07-01",level:2},{value:"Changed",id:"changed-4",level:3}],m={toc:d};function p(e){let{components:t,...n}=e;return(0,a.kt)("wrapper",(0,l.Z)({},m,n,{components:t,mdxType:"MDXLayout"}),(0,a.kt)("h2",{id:"2022-07-08"},"2022-07-08"),(0,a.kt)("h3",{id:"added"},"Added"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Added ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:wait"),".")),(0,a.kt)("h3",{id:"changed"},"Changed"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Removed ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:disonnectAll")," and ",(0,a.kt)("inlineCode",{parentName:"li"},"ClientRemoteSignal:disonnectAll"),"."),(0,a.kt)("li",{parentName:"ul"},"Removed ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:connectOnce")," and ",(0,a.kt)("inlineCode",{parentName:"li"},"ClientRemoteSignal:connectOnce"),"."),(0,a.kt)("li",{parentName:"ul"},"Fix bug with ",(0,a.kt)("inlineCode",{parentName:"li"},"ClientRemoteSignal:connect")," and ",(0,a.kt)("inlineCode",{parentName:"li"},"ClientRemoteSignal:wait")," not receiving the dispatched events properly in some edge cases."),(0,a.kt)("li",{parentName:"ul"},(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:connect")," and ",(0,a.kt)("inlineCode",{parentName:"li"},"ClientRemoteSignal:connect")," now return an ",(0,a.kt)("inlineCode",{parentName:"li"},"RBXScriptConnectionObject"),". "),(0,a.kt)("li",{parentName:"ul"},"Internal code refactor and improvements."),(0,a.kt)("li",{parentName:"ul"},"Documentation improvements.")),(0,a.kt)("h2",{id:"2022-07-07"},"2022-07-07"),(0,a.kt)("h3",{id:"added-1"},"Added"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Added ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:fireAllClientsExcept"),".")),(0,a.kt)("h3",{id:"changed-1"},"Changed"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Change ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:fireForClients")," to ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteSignal:fireClients"),"."),(0,a.kt)("li",{parentName:"ul"},"Internal code refactor for ",(0,a.kt)("inlineCode",{parentName:"li"},"network"),"."),(0,a.kt)("li",{parentName:"ul"},"Documentation improvements for ",(0,a.kt)("inlineCode",{parentName:"li"},"network"),".")),(0,a.kt)("h2",{id:"2022-07-03"},"2022-07-03"),(0,a.kt)("h3",{id:"added-2"},"Added"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Added ",(0,a.kt)("inlineCode",{parentName:"li"},"numberUtil.formatToHMS"),"."),(0,a.kt)("li",{parentName:"ul"},"Added ",(0,a.kt)("inlineCode",{parentName:"li"},"numberUtil.formatToMS"),".")),(0,a.kt)("h3",{id:"changed-2"},"Changed"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Improve error checking within ",(0,a.kt)("inlineCode",{parentName:"li"},"windLines")," module."),(0,a.kt)("li",{parentName:"ul"},"Improve documentation."),(0,a.kt)("li",{parentName:"ul"},"Rename ",(0,a.kt)("inlineCode",{parentName:"li"},"numberUtil.format")," to ",(0,a.kt)("inlineCode",{parentName:"li"},"numberUtil.suffix"),".")),(0,a.kt)("h2",{id:"2022-07-02"},"2022-07-02"),(0,a.kt)("h3",{id:"changed-3"},"Changed"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Fix middleware related bugs within the ",(0,a.kt)("inlineCode",{parentName:"li"},"network")," module."),(0,a.kt)("li",{parentName:"ul"},"Improve method names within ",(0,a.kt)("inlineCode",{parentName:"li"},"RemoteProperty"),".")),(0,a.kt)("h2",{id:"2022-07-01"},"2022-07-01"),(0,a.kt)("h3",{id:"changed-4"},"Changed"),(0,a.kt)("ul",null,(0,a.kt)("li",{parentName:"ul"},"Rework all libraries to follow the Roblox lua style guide."),(0,a.kt)("li",{parentName:"ul"},"Implement middleware support for remote properties and remote signals."),(0,a.kt)("li",{parentName:"ul"},"Improve documentation of all libraries.")))}p.isMDXComponent=!0}}]);