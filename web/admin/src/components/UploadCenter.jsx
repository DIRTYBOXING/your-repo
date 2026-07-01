import React from "react";

export default function UploadCenter() {
  const [status, setStatus] = React.useState("idle");

  const onFile = async (e) => {
    const f = e.target.files[0];
    if (!f) return;
    setStatus("uploading");
    const fd = new FormData();
    fd.append("file", f);
    fd.append("metadata", JSON.stringify({ uploader: "admin" }));
    const res = await fetch("/api/upload", { method: "POST", body: fd });
    const json = await res.json();
    setStatus(json.scanStatus || "done");
  };

  return (
    <div className="bg-white p-3 rounded shadow">
      <h3 className="font-semibold mb-2">Upload Center</h3>
      <input type="file" onChange={onFile} />
      <div className="mt-2 text-sm text-gray-500">Status: {status}</div>
    </div>
  );
}
