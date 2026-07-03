function normalizeGym(json = {}) {
  return {
    name: json.name || "",
    location: json.location || "",
    imageUrl: json.imageUrl || "",
    stats: json.stats || {},
    coaches: Array.isArray(json.coaches) ? json.coaches : [],
    roster: Array.isArray(json.roster) ? json.roster : [],
    schedule: Array.isArray(json.schedule) ? json.schedule : [],
  };
}

module.exports = {
  normalizeGym,
};
