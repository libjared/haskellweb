{-# LANGUAGE BlockArguments    #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.JSString (JSString)
import GHCJS.Foreign.Callback (Callback)
import GHCJS.Types (JSVal)
import JavaScript.Array (JSArray)

import qualified Data.JSString as JSString
import qualified GHCJS.Foreign.Callback as Callback
import qualified JavaScript.Array as Array

foreign import javascript unsafe "document.getElementById($1)"
    getElementById :: JSString -> IO JSVal

foreign import javascript unsafe "$1.textContent = $2"
    setTextContent :: JSVal -> JSString -> IO ()

foreign import javascript unsafe "$1.value"
    getValue :: JSVal -> IO JSString

foreign import javascript unsafe "$1.value = $2"
    setValue :: JSVal -> JSString -> IO ()

foreign import javascript unsafe "$1.addEventListener($2, $3)"
    addEventListener :: JSVal -> JSString -> Callback (IO ()) -> IO ()

foreign import javascript unsafe "document.createElement($1)"
    createElement :: JSString -> IO JSVal

foreign import javascript unsafe "$1.appendChild($2)"
    appendChild :: JSVal -> JSVal -> IO ()

foreign import javascript unsafe "$1.setAttribute($2, $3)"
    setAttribute :: JSVal -> JSString -> JSString -> IO ()

foreign import javascript unsafe "replaceChildrenWorkaround($1, $2)"
    replaceChildren_ :: JSVal -> JSArray -> IO ()

replaceChildren :: JSVal -> [JSVal] -> IO ()
replaceChildren a b = replaceChildren_ a (Array.fromList b)

foreign import javascript unsafe "$1.remove()"
    remove :: JSVal -> IO ()

main :: IO ()
main = do
    textbox <- getElementById "text-add"
    addButton <- getElementById "button-add"
    itemList <- getElementById "items"

    addCallback <- Callback.asyncCallback do
        text <- getValue textbox
        setValue textbox ""

        checkbox <- createElement "input"
        setAttribute checkbox "type" "checkbox"

        label <- createElement "label"
        setTextContent label text

        newItem <- createElement "li"
        replaceChildren newItem [ checkbox, label ]

        doneCallback <- Callback.asyncCallback (remove newItem)
        addEventListener checkbox "click" doneCallback

        appendChild itemList newItem

    addEventListener addButton "click" addCallback
